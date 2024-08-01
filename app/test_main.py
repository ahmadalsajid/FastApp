from fastapi.testclient import TestClient
from .main import app

client = TestClient(app)


def test_homepage():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"Hello": "World"}


def test_greetings_without_name():
    response = client.get("/greetings/")
    assert response.status_code == 404
    assert response.json() == {"detail": "Not Found"}


def test_greetings_with_name():
    response = client.get("/greetings/sajid")
    assert response.status_code == 200
    assert response.json() == {"Hello": "sajid", "q": None}

def test_greetings_with_name_and_q():
    response = client.get("/greetings/sajid?q=fail")
    assert response.status_code == 200
    assert response.json() == {"Hello": "sajid", "q": "fail"}

# #intended to fail
# def test_greetings_with_name_and_q_fail():
#     response = client.get("/greetings/sajid?q=fail")
#     assert response.status_code == 200
#     assert response.json() == {"Hello": "sajid", "q": None}
