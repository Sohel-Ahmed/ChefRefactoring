from db_api import app

import logging

gunicorn_logger = logging.getLogger('gunicorn')
app.logger.handlers = gunicorn_logger.handlers
app.logger.setLevel(gunicorn_logger.level)

if __name__ == '__main__':
    app.run()
