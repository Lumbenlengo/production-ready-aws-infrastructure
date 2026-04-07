output "web_sg_id" {
  value = aws_security_group.web_sg.id
}



output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}
