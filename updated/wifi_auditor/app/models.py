from datetime import datetime
from app import db
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

class User(UserMixin, db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), index=True, unique=True, nullable=False)
    email = db.Column(db.String(120), index=True, unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    role = db.Column(db.String(32), default='auditor', nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    last_seen = db.Column(db.DateTime, default=datetime.utcnow)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    scans = db.relationship('Scan', backref='operator', lazy='dynamic')
    logs = db.relationship('AuditLog', backref='user', lazy='dynamic')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def __repr__(self):
        return f'<User {self.username}>'

class AuditLog(db.Model):
    __tablename__ = 'audit_logs'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    action = db.Column(db.String(128), nullable=False)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    timestamp = db.Column(db.DateTime, index=True, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<AuditLog {self.action} by {self.user_id} at {self.timestamp}>'

class Scan(db.Model):
    __tablename__ = 'scans'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    target_bssid = db.Column(db.String(17), nullable=False)
    target_ssid = db.Column(db.String(64))
    channel = db.Column(db.Integer)
    encryption = db.Column(db.String(32))
    start_time = db.Column(db.DateTime, default=datetime.utcnow)
    end_time = db.Column(db.DateTime)
    status = db.Column(db.String(32), default='pending')
    capture_file = db.Column(db.String(128))
    handshake_captured = db.Column(db.Boolean, default=False)
    
    # Relationships
    findings = db.relationship('Finding', backref='scan', lazy='dynamic')
    reports = db.relationship('Report', backref='scan', lazy='dynamic')
    
    def duration(self):
        if self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return None
    
    def __repr__(self):
        return f'<Scan {self.target_bssid}>'

class Finding(db.Model):
    __tablename__ = 'findings'
    
    id = db.Column(db.Integer, primary_key=True)
    scan_id = db.Column(db.Integer, db.ForeignKey('scans.id'))
    severity = db.Column(db.String(16), nullable=False)
    title = db.Column(db.String(128), nullable=False)
    description = db.Column(db.Text)
    impact = db.Column(db.Text)
    recommendation = db.Column(db.Text)
    evidence = db.Column(db.Text)
    cve_reference = db.Column(db.String(32))
    
    def __repr__(self):
        return f'<Finding {self.title}>'

class Report(db.Model):
    __tablename__ = 'reports'
    
    id = db.Column(db.Integer, primary_key=True)
    scan_id = db.Column(db.Integer, db.ForeignKey('scans.id'))
    generated_by = db.Column(db.Integer, db.ForeignKey('users.id'))
    generation_date = db.Column(db.DateTime, default=datetime.utcnow)
    report_type = db.Column(db.String(32), default='full')
    file_path = db.Column(db.String(256))
    executive_summary = db.Column(db.Text)
    
    def __repr__(self):
        return f'<Report for Scan {self.scan_id}>'

class Device(db.Model):
    __tablename__ = 'devices'
    
    id = db.Column(db.Integer, primary_key=True)
    scan_id = db.Column(db.Integer, db.ForeignKey('scans.id'))
    mac_address = db.Column(db.String(17), nullable=False)
    manufacturer = db.Column(db.String(64))
    first_seen = db.Column(db.DateTime)
    last_seen = db.Column(db.DateTime)
    signal_strength = db.Column(db.Integer)
    packets_captured = db.Column(db.Integer)
    
    def __repr__(self):
        return f'<Device {self.mac_address}>'
