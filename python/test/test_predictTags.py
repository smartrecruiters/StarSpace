import starwrap as sw
import numpy as np
from operator import itemgetter
import os
import pytest


@pytest.fixture
def sp():
    arg = sw.args()
    arg.trainFile = "./tagged_post.txt"
    arg.trainMode = 0

    sp = sw.starSpace(arg)
    sp.init()
    sp.train()

    sp.nearestNeighbor("barack", 10)

    yield sp


def test_train_model(sp):

    dict_obj = sp.predictTags("barack obama", 10)
    dict_obj = sorted(dict_obj.items(), key=itemgetter(1), reverse=True)

    for tag, prob in dict_obj:
        print(tag, prob)

    for tag, prob in dict_obj:
        assert tag != None
        assert prob != None


def test_init_from_model(sp):
    os.makedirs("tmp", exist_ok=True)

    sp.saveModel(os.path.join("tmp", "tagged_model"))
    sp.saveModelTsv(os.path.join("tmp", "tagged_model.tsv"))

    sp2 = sw.starSpace(sw.args())
    sp2.initFromSavedModel(os.path.join("tmp", "tagged_model"))
    sp2.initFromTsv(os.path.join("tmp", "tagged_model.tsv"))

    dict_obj = sp2.predictTags("barack obama", 10)
    dict_obj = sorted(dict_obj.items(), key=itemgetter(1), reverse=True)

    for tag, prob in dict_obj:
        print(tag, prob)

    for tag, prob in dict_obj:
        assert tag != None
        assert prob != None


if __name__ == "__main__":
    pytest.main()
