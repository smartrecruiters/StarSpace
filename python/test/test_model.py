import starwrap as sw
import numpy as np
import os
import pytest


@pytest.fixture
def sp():
    arg = sw.args()
    arg.trainFile = "./input.txt"
    arg.testFile = "./input.txt"
    arg.trainMode = 5

    sp = sw.starSpace(arg)
    sp.init()
    sp.train()
    # sp.evaluate()

    sp.nearestNeighbor("some text", 10)

    yield sp


def test_train_model(sp):

    result1 = np.array(sp.getDocVector("this\tis\ttest", "\t"))
    result2 = np.array(sp.getDocVector("this is test", " "))

    print(f"result1: ${result1}")
    print(f"result2: ${result2}")

    assert (result1 == result2).all()


def test_init_from_model(sp):
    os.makedirs("tmp", exist_ok=True)

    sp.saveModel(os.path.join("tmp", "model"))
    sp.saveModelTsv(os.path.join("tmp", "model.tsv"))

    arg = sw.args()
    sp2 = sw.starSpace(arg)
    sp2.initFromSavedModel(os.path.join("tmp", "model"))
    sp2.initFromTsv(os.path.join("tmp", "model.tsv"))

    result1 = np.array(sp2.getDocVector("this\tis\ttest", "\t"))
    result2 = np.array(sp2.getDocVector("this is test", " "))
    print(f"result1: ${result1}")
    print(f"result2: ${result2}")

    assert (result1 == result2).all()


if __name__ == "__main__":
    pytest.main()
