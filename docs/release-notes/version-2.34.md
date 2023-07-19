# Topolograph

## v2.34 (20.07.2023)

## New features
Multi LSDBs upload support https://github.com/Vadims06/topolograph/issues/37, https://github.com/Vadims06/topolograph/issues/39. Available via API.

#### Multi LSDBs upload via API 
If a network has multiple areas, it is needed to get LSDB output from multiple devices and save it into separate files. Example below uses two LSDB outputs saved in the `lsdb_samples` folder.
![](https://github.com/Vadims06/topolograph/blob/2bdf44ea4701bd2d05531e9020c6bad38c945b4b/docs/release-notes/v2.34/multi_lsdb_upload_post_request.png)
* [Cisco_ospf.txt](https://github.com/Vadims06/topolograph/blob/3939983fdd859180a5ced8b2528bc558b106177a/docs/release-notes/v2.34/Cisco_ospf.txt)
* [Juniper_ospf.txt](https://github.com/Vadims06/topolograph/blob/3939983fdd859180a5ced8b2528bc558b106177a/docs/release-notes/v2.34/Juniper_ospf.txt)  
Python sample code:  
```
import requests
TOPOLOGRAPH_HOST="127.0.0.1"
TOPOLOGRAPH_PORT=5000
TOPOLOGRAPH_WEB_API_USERNAME_EMAIL="your login"
TOPOLOGRAPH_WEB_API_PASSWORD="your password"
from pprint import pprint as pp

lsdbs_attr_ll = []
lsdb_dir = os.path.join(os.getcwd(), 'lsdb_samples')
for vendor_name, protocol_name in [('Cisco', 'ospf'), ('Juniper', 'ospf')]:
  f_name = os.path.join(lsdb_dir, f"{vendor_name}_{protocol_name}.txt")
  with open(f_name) as f:
    lsdbs_attr_ll.append({'lsdb_output': f.read(), 'vendor_device': vendor_name, 'igp_protocol': protocol_name})
r_post = requests.post(f'http://{TOPOLOGRAPH_HOST}:{TOPOLOGRAPH_PORT}/api/graphs', auth=(TOPOLOGRAPH_WEB_API_USERNAME_EMAIL, TOPOLOGRAPH_WEB_API_PASSWORD),  json=lsdbs_attr_ll, timeout=(5, 30))
pp(r_post.json())
```
