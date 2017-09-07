import re
import os.path
import itertools
import collections

from twisted.logger import Logger
from AUR.SRCINFO import AurSrcinfo
import requests
import yaml


log = Logger('aur_buildbot.packages')

_aur_srcinfo = AurSrcinfo(dbpath=os.path.join(basedir, 'aur.cache'))

_package_cache_file = os.path.join(basedir, 'packages.cache')
try:
    with open(_package_cache_file, 'r') as stream:
        _package_cache = yaml.load(stream)
        if _package_cache is None:
            _package_cache = {}
except Exception:
    _package_cache = {}



_remove_version_regex = re.compile('^[^=><]+')
def _remove_versions(packages):
    return (_remove_version_regex.match(p).group(0) for p in packages)

_source_url_regex = re.compile('^(?P<folder>.+(?=::))?(?:::)?(?:(?P<vcs>git|svn|hg|cvs|bzr)\+)?(?P<url>[^#]+)#?(?P<fragment>[^#]+$)?')
def _parse_source_url(url):
    return _source_url_regex.search(url).groupdict()

def aur_info(packages):
    if not isinstance(packages, collections.Sequence) or isinstance(packages, str):
        input_list = False
        packages = [packages]
    else:
        input_list = True
 
    results = requests.get('https://aur.archlinux.org/rpc/', 
                           params={'v': '5', 'type': 'info', 'arg[]': packages}).json()
    results = results['results']
    if input_list:
        return results
    else:
        assert len(results) <= 1
        return results[0] if len(results) > 0 else None
        
def aur_url(package):
    return 'https://aur.archlinux.org/{}.git'.format(package)

def find_dependencies(packages):
    all_packages = {}
    package_queue = collections.deque(packages.items())
    
    while package_queue:
        package, config_info = package_queue.pop()
        log.debug("Processing package: {package}", package=package)
        
        full_info = _package_cache.get(package, None)
        if full_info is None:
            full_info = {}
            _package_cache[package] = full_info
            # Retrieve pkgbase from AUR
            log.debug("'{package}' not found in cache, searching AUR", package=package)
            
            remote_info = aur_info(package)
            if remote_info is None:
                # Mark package as not found in the AUR and skip further
                # processing
                _package_cache[package] = {'aur': False}
                log.debug("'{package}' not found AUR", package=package)
                continue

            package_base = remote_info['PackageBase']
            if package_base != package:
                # Link package to its base
                full_info['package_base'] = package_base
                _package_cache.setdefault(package_base, {})
                log.debug("Linking '{package}' to '{package_base}' in cache", 
                    package=package,
                    package_base=package_base
                )

        
        # Stop processing if the package is not found in the AUR
        if not full_info.get('aur', True):
            log.debug("'{package}' is not an AUR package", package=package)
            continue
        
        
        # If the current package is part of a split package, switch to 
        # processing the base
        package_base = full_info.get('package_base', None)
        if package_base is not None:
            package = package_base
            full_info = _package_cache[package]
        
        if ('architectures' not in full_info or 
            'dependencies' not in full_info or
            'sources' not in full_info):
            # Get .SRCINFO to fill in rest of information
            log.debug("Cached info for '{package}' not complete, retrieving .SRCINFO", package=package)
            srcinfo = next(_aur_srcinfo.get([package]))
            pkgbase_srcinfo = srcinfo['pkgbase'][1]
            architectures = pkgbase_srcinfo['arch']
            full_info['architectures'] = architectures
            
            dependencies = set()
            dependencies.update(_remove_versions(pkgbase_srcinfo.get('depends', tuple())))
            dependencies.update(_remove_versions(pkgbase_srcinfo.get('makedepends', tuple())))
            for split_srcinfo in srcinfo['pkgname'].values():
                dependencies.update(_remove_versions(split_srcinfo.get('depends', tuple())))
                dependencies.update(_remove_versions(split_srcinfo.get('makedepends', tuple())))
            
            full_info['dependencies'] = dependencies
            
            full_info['sources'] = [_parse_source_url(s) for s in pkgbase_srcinfo['source']]
            
        _package_cache[package] = full_info
        
        new_package = False
        try:
            output_info = all_packages[package]
        except KeyError:
            # If we have never seen this package before, copy its information
            # from the AUR info
            new_package = True
            output_info = full_info.copy()
            all_packages[package] = output_info
        
        # Add dependencies from config
        output_info['extra_dependencies'] = set(config_info.get('dependencies', set())) - set(output_info.get('dependencies', set()))
        
        # Merge architectures from previous iterations, from the config and from
        # the AUR
        new_architectures = False
        config_architectures = set(config_info.get('architectures', set()))
        srcinfo_architectures = set(full_info.get('architectures', set()))
        if 'any' in srcinfo_architectures:
            assert len(srcinfo_architectures) == 1
            output_architectures = srcinfo_architectures
            propogate_architectures = config_info.get('architectures', set())
            new_architectures = len(propogate_architectures) > 0
        else:
            output_architectures = (
                config_architectures |
                srcinfo_architectures |
                set(output_info.get('architectures', set()))
            )
            propogate_architectures = output_architectures
            new_architectures = output_info.get('architectures', set()) != propogate_architectures
        if new_architectures:
            output_info['architectures'] = output_architectures
        
        assert 'any' not in propogate_architectures
        
        # Propogate architectures to all dependencies if architectures changed 
        # or that package was never seen before
        if new_package or new_architectures:
            package_queue.extend(zip(
                output_info['dependencies'],
                itertools.repeat({
                    'architectures': propogate_architectures
                })
            ))
    
    with open(_package_cache_file, 'w') as stream:
        yaml.dump(_package_cache, stream)
    
    return all_packages

