-- Seed data for development and testing

-- Insert test organization
INSERT INTO organizations (id, name, slug, status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Test Organization', 'test-org', 'active')
ON CONFLICT DO NOTHING;

-- Insert test users (password: password123)
INSERT INTO users (id, org_id, email, password_hash, name, status) VALUES
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 
     'admin@test.com', '$2a$10$rO.7W5JxZxZbDZQRQs4kRO5N3f7YJDqYZ1v4qW8sT6nF3s8H2mGKC', 'Admin User', 'active'),
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001',
     'user@test.com', '$2a$10$rO.7W5JxZxZbDZQRQs4kRO5N3f7YJDqYZ1v4qW8sT6nF3s8H2mGKC', 'Regular User', 'active')
ON CONFLICT DO NOTHING;

-- Assign roles
INSERT INTO user_roles (user_id, org_id, role) VALUES
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'admin'),
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'user')
ON CONFLICT DO NOTHING;

-- Insert test DSP connector
INSERT INTO dsp_connectors (id, org_id, dsp_type, name, credentials, status) VALUES
    ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001',
     'dv360', 'Test DV360 Connector', 
     '{"client_id": "test_client", "client_secret": "test_secret", "refresh_token": "test_token"}'::jsonb, 'active')
ON CONFLICT DO NOTHING;

-- Insert test campaign
INSERT INTO campaigns (id, org_id, dsp_connector_id, name, status, budget, start_date, end_date) VALUES
    ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001',
     '20000000-0000-0000-0000-000000000001', 'Test Campaign Q1 2026', 'active', 10000.00, '2026-01-01', '2026-03-31')
ON CONFLICT DO NOTHING;

SELECT 'Seed data loaded successfully!' AS status;
