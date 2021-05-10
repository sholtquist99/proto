from UF import *


def main():
    print("Project Proto\n" + "="*64)
    uf = UF(5)
    uf.unite(0, 1)
    uf.unite(1, 2)
    uf.unite(3, 4)
    print(uf.disjointRegions())


if __name__ == "__main__":
    main()
