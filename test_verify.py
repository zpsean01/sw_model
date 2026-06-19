"""Verify ztree endpoint and frontend files."""
import json, urllib.request

# Test ztree returns flat simpleData
r = json.loads(urllib.request.urlopen("http://localhost:8000/api/v1/sw_model/ztree").read())
print("ztree simpleData:")
for n in r:
    print(f'  id={n["id"]:30s} pId={n["pId"]:4s} isParent={n["isParent"]:5s} name={n["name"]}')
print(f"total nodes: {len(r)}")

# Test frontend proxy + static resources
r = urllib.request.urlopen("http://localhost:5007/js/common/ztree-common.js").read()
print(f"\nztree-common.js: {len(r)} bytes")

r = urllib.request.urlopen("http://localhost:5007/js/features/app.js").read()
print(f"app.js: {len(r)} bytes")

r = urllib.request.urlopen("http://localhost:5007/").read().decode()
print(f"index.html: {len(r)} bytes, has ztree-common: {'ztree-common' in r}")

# Test API proxy still works
r = json.loads(urllib.request.urlopen("http://localhost:5007/api/v1/sw_model/ztree").read())
print(f"\nFrontend proxy ztree: {len(r)} nodes")