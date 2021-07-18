FROM python:3.8-alpine
RUN pip install --no-cache-dir awscli==1.20.1
COPY ./s3-sync.py .
ENTRYPOINT [ "./s3-sync.py" ]
