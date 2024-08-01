from typing import Union

from fastapi import FastAPI

app = FastAPI()


@app.get("/")
async def homepage():
    return {"Hello": "World"}


@app.get("/greetings/{guest_name}")
async def greetings(guest_name: str, q: Union[str, None] = None):
    return {
        "Hello": guest_name,
        "q": q
    }
