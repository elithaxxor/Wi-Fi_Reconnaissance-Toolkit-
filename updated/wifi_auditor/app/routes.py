from flask import render_template, request, jsonify, send_file
from app import app, db
from app.models import ScanResult, Report
from app.tasks import run_scan_task, generate_report_task

@app.route('/')
def dashboard():
    return render_template('dashboard.html')

@app.route('/start_scan', methods=['POST'])
def start_scan():
    config = {
        'interface': request.form.get('interface'),
        'channel': request.form.get('channel'),
        'mac': request.form.get('mac')
    }
    task = run_scan_task.delay(config)
    return jsonify({'task_id': task.id}), 202

@app.route('/report/<scan_id>')
def download_report(scan_id):
    report = Report.query.filter_by(scan_id=scan_id).first()
    return send_file(report.filepath, as_attachment=True)
