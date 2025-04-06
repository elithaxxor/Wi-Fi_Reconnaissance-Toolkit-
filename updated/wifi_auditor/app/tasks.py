from celery import Celery
from app import create_app
from utils.scanner import WiFiScanner
from utils.reporter import PDFReporter

celery = Celery(__name__, broker='redis://redis:6379/0')

@celery.task
def run_scan_task(config):
    app = create_app()
    with app.app_context():
        scanner = WiFiScanner(config)
        return scanner.execute_scan()

@celery.task
def generate_report_task(scan_id):
    app = create_app()
    with app.app_context():
        reporter = PDFReporter(scan_id)
        return reporter.generate()
