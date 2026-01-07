-- ============================================================================
-- HELPFUL QUERIES FOR TESTING
-- ============================================================================

-- List all users with their organizations
SELECT u.email, o.name as org_name, om.role 
FROM users u 
JOIN org_memberships om ON u.id = om.user_id 
JOIN organizations o ON om.org_id = o.id;

-- List all pipelines with last execution status
SELECT p.name, p.status, p.last_run_status, p.next_run_at 
FROM pipelines p 
ORDER BY p.last_run_at DESC;

-- List all campaigns with today's metrics
SELECT c.name, cm.metric_date, cm.impressions, cm.clicks, cm.spend, cm.ctr 
FROM campaigns c 
JOIN campaign_metrics cm ON c.id = cm.campaign_id 
WHERE cm.metric_date = CURRENT_DATE;

-- Check data quality issues
SELECT p.name, dqm.layer, dqm.metric_name, dqm.fail_count 
FROM data_quality_metrics dqm 
JOIN pipelines p ON dqm.pipeline_id = p.id 
WHERE dqm.fail_count > 0;