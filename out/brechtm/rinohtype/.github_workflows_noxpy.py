# Set NOXPY env var based on GitHub Actions' set-python version

import os
import sys

_, github_python_version = sys.argv

mapping = {'3.6':                 '3.6',
           '3.7':                 '3.7',
           '3.8':                 '3.8',
           '3.9':                 '3.9',
           '3.10.0-alpha - 3.10': '3.10',
           'pypy-3.6':            'pypy3',
           'pypy-3.7':            'pypy3'}

noxenv = os.getenv('NOXENV')
pyfactor = mapping[github_python_version]

if noxenv in ('unit', 'regression'):
    with open(os.getenv('GITHUB_ENV'), 'a') as env:
        print(f'NOXENV={noxenv}-{pyfactor}', file=env)
