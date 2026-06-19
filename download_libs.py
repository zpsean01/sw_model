"""Download third-party libraries for the frontend."""
import os
import urllib.request

LIB = r"D:\programming\sw_model\frontend\js\lib"

# 1. jQuery
print("Downloading jQuery...")
urllib.request.urlretrieve(
    "https://code.jquery.com/jquery-3.7.1.min.js",
    os.path.join(LIB, "jquery.min.js"),
)

# 2. jsoneditor
print("Downloading jsoneditor...")
urllib.request.urlretrieve(
    "https://cdn.jsdelivr.net/npm/jsoneditor@9.10.0/dist/jsoneditor.min.js",
    os.path.join(LIB, "jsoneditor.min.js"),
)
urllib.request.urlretrieve(
    "https://cdn.jsdelivr.net/npm/jsoneditor@9.10.0/dist/jsoneditor.min.css",
    os.path.join(LIB, "jsoneditor.min.css"),
)

# 3. zTree
ZTREE_LIB = os.path.join(LIB, "ztree")
os.makedirs(os.path.join(ZTREE_LIB, "img"), exist_ok=True)
os.makedirs(os.path.join(ZTREE_LIB, "img", "diy"), exist_ok=True)

print("Downloading zTree JS...")
# Use jsdelivr's gh proxy for raw GitHub files
urllib.request.urlretrieve(
    "https://cdn.jsdelivr.net/gh/zTree/zTree_v3@master/js/jquery.ztree.all.min.js",
    os.path.join(ZTREE_LIB, "jquery.ztree.all.min.js"),
)

print("Downloading zTree CSS...")
urllib.request.urlretrieve(
    "https://cdn.jsdelivr.net/gh/zTree/zTree_v3@master/css/zTreeStyle/zTreeStyle.css",
    os.path.join(ZTREE_LIB, "zTreeStyle.css"),
)

print("Downloading zTree images...")
img_urls = {
    "line_conn.gif": "css/zTreeStyle/img/line_conn.gif",
    "loading.gif": "css/zTreeStyle/img/loading.gif",
    "zTreeStandard.gif": "css/zTreeStyle/img/zTreeStandard.gif",
    "zTreeStandard.png": "css/zTreeStyle/img/zTreeStandard.png",
    "diy/1_open.png": "css/zTreeStyle/img/diy/1_open.png",
    "diy/1_close.png": "css/zTreeStyle/img/diy/1_close.png",
}
for name, path in img_urls.items():
    url = f"https://cdn.jsdelivr.net/gh/zTree/zTree_v3@master/{path}"
    dest = os.path.join(ZTREE_LIB, "img", name)
    try:
        urllib.request.urlretrieve(url, dest)
        print(f"  OK: {name}")
    except Exception as e:
        print(f"  FAIL: {name} - {e}")

print("\nAll downloads complete!")