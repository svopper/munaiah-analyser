import pandas as pd
import os
import requests

# repository,language,architecture,community,continuous_integration,documentation,history,issues,license,size,unit_test,stars,scorebased_org,randomforest_org,scorebased_utl,randomforest_utl

df = pd.read_csv('./out.csv', low_memory=False)

df = df[df['randomforest_utl'] == 1]['repository']

compression_opts = dict(method='zip',
                        archive_name='out.csv')
df.to_csv('out2.zip', index=False,
          compression=compression_opts)
