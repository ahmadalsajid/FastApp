FROM python:3.10-slim

WORKDIR /code

COPY requirements.txt /code/

RUN python -m pip install --upgrade pip
RUN pip install -r requirements.txt

COPY . /code/

EXPOSE 8000

CMD [ "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2" ]