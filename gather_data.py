#!/bin/env python3
import subprocess
import hashlib
import sqlite3
import json
import os.path

# all files that on which data could depend
IMPORTANT_FILES = ["gather_data.py", "Makefile", "main.c"]
DATABASE_NAME = "data.json"

def _get_hash(file, hasher, blocksize=65536):
    """
    feed hasher with file.

    WARNING: mutates `hasher`
    """
    with open(file, "rb") as f:
        inp = f.read(blocksize)
        while len(inp) > 0:
            hasher.update(inp)
            inp = f.read(blocksize)

def get_hash(files):
    """Get the combined hash of files for identification"""
    hasher = hashlib.sha256()
    for f in files:
        _get_hash(f, hasher)

    return hasher.hexdigest()

def get_git_version():
    process = subprocess.run(["git", "rev-parse", "HEAD"], stdout=subprocess.PIPE)
    git_id = process.stdout.decode("utf-8").replace("\n", "")
    return git_id

def check_database():
    if os.path.exists(DATABASE_NAME):
        pass
    else:
        with open(DATABASE_NAME, mode="w", encoding="utf-8") as f:
            f.write("[")

def write_data(data):
    with open(DATABASE_NAME, mode="a", encoding="utf-8") as f:
        f.write(data)

def main(n_max=1000, timeout=60, repitition=1, n_step=100, max_cores=6):
    """
    generate some data

    max_cores (int) - how many cores to use maximally
    n_max     (int) - how big the dimension will be sized maximally
    timeout   (int) - how long to wait for a single run
    """

    check_database()

    file_hash = get_hash(IMPORTANT_FILES)
    git_id = get_git_version()

    for _ in range(repitition):
        data = []

        for cores in [2**i for i in range(1, max_cores+1)]:
            for n in range(100, n_max+n_step, n_step):
                try:
                    cp = subprocess.run(["./main", str(n), str(cores)], stdout=subprocess.PIPE, check=True, timeout=timeout)
                    datapoint = json.loads(cp.stdout.decode("utf-8"))
                    data.append(datapoint)
                except subprocess.TimeoutExpired as e:
                    datapoint = {"type": "error", "msg": "Timeout"}
                    data.append(datapoint)
                    break

        for dat in data:
            serialized = json.dumps({"file_hash": file_hash, "git_id": git_id, "data": dat})
            write_data(serialized + ",\n")

if __name__ == "__main__":
    main(n_max=4000, repitition=3)



