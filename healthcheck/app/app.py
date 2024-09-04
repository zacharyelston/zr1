from flask import Flask, jsonify, request
from os import environ
from prometheus_client import make_wsgi_app, Counter, Histogram
from werkzeug.middleware.dispatcher import DispatcherMiddleware
import time
import requests 
from requests.auth import HTTPBasicAuth 

app = Flask(__name__)

app.config['RPUSER'] = environ.get('RPUSER')
app.config['RPPASS'] = environ.get('RPPASS')
app.config['RPAUTH'] = environ.get('RPAUTH')
app.config['RPURL'] = environ.get('RPURL')

app.wsgi_app = DispatcherMiddleware(app.wsgi_app, {
    '/metrics': make_wsgi_app()
})

REQUEST_COUNT = Counter(
    'app_request_count',
    'Application Request Count',
    ['method', 'endpoint', 'http_status']
)

REQUEST_LATENCY = Histogram(
    'app_request_latency_seconds',
    'Application Request Latency',
    ['method', 'endpoint']
)

@app.route('/')
def hello():
    start_time = time.time()
    REQUEST_COUNT.labels('GET', '/', 200).inc()

    response = jsonify(message='Hello, world!')
    REQUEST_LATENCY.labels('GET', '/').observe(time.time() - start_time) 
    return response

@app.route('/cheese')
def cheese():
    start_time = time.time()
    REQUEST_COUNT.labels('GET', '/cheese', 200).inc()

    response = jsonify(message='nacho?!')
    REQUEST_LATENCY.labels('GET', '/cheese').observe(time.time() - start_time) 
    return response

@app.route('/redpanda')
def redpanda():
    url = environ.get('RPURL')
    username = environ.get('RPUSER')
    password = environ.get('RPPASS')
    rpdata = requests.get(url, auth=HTTPBasicAuth(username, password)) 
    return rpdata.content

@app.route('/google')
def google():
    url = 'https://www.google.com'
    rpdata = requests.get(url) 
    start_time = time.time()
    REQUEST_COUNT.labels('GET', '/google', 200).inc()
    REQUEST_LATENCY.labels('GET', '/google').observe(time.time() - start_time)
    return rpdata.content
    

if __name__ == '__main__':
            app.run(host='0.0.0.0', port=5000)