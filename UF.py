"""
UNION-FIND
based on Princeton WQUPC implementation
    see https://www.cs.princeton.edu/~rs/AlgsDS07/01UnionFind.pdf
"""


class UF:
    def __init__(self, N):
        self.id = [x for x in range(N)]
        self.sz = [x for x in range(N)]

    def root(self, i):
        while i != self.id[i]:
            self.id[i] = self.id[self.id[i]]
            i = self.id[i]
        return i

    def find(self, p, q):
        return self.root(p) == self.root(q)

    def unite(self, p, q):
        i = self.root(p)
        j = self.root(q)
        if self.sz[i] < self.sz[j]:
            self.id[i] = j
            self.sz[j] = self.sz[j] + self.sz[i]
        else:
            self.id[j] = i
            self.sz[i] = self.sz[i] + self.sz[j]

    def add(self, b):
        if b >= len(self.id):
            for i in range(len(self.id), b):
                self.id.append(i)
                self.sz.append(0)
            self.id.append(b)
            self.sz.append(1)

    def uniteAll(self, list):
        for item in list:
            self.add(item)

    def disjointRegions(self):
        ret = {}
        for i in range(len(self.id)):
            root = self.root(i)
            region = ret.get(root, [])
            region.append(i)
            ret[root] = region
        return ret
