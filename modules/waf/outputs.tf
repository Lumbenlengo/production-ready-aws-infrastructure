# modules/waf/outputs.tf

output "waf_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_name" {
  description = "WAF Web ACL name"
  value       = aws_wafv2_web_acl.main.name
}

output "association_id" {
  description = "WAF association ID (null if not associated)"
  value       = try(aws_wafv2_web_acl_association.main[0].id, null)
}
