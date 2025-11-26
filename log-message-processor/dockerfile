# Python log processor
FROM python:3.8
WORKDIR /app
COPY requirements.txt .
# First install C dependencies needed for thriftpy2
RUN apt-get update && apt-get install -y gcc python3-dev
# Then install Python requirements
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "main.py"]
