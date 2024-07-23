# Enable to log every request
accesslog = "-"
errorlog = "-"
preload_app = True
workers = 1
worker_class = "gevent"

# SSL Certs
keyfile = "/certs/registry.spacefx.local.key"  # Path to your private key file
certfile = "/certs/registry.spacefx.local.crt"  # Path to your certificate file

bind = "0.0.0.0:8080"