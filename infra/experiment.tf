# # Example how to mix and match HTTP "health_check" with "path" and "matcher" for HTTP code 200 and Target group with TCP protocol when dealing with Network Load Balancer (NLB) in AWS.
# # It wasn't very straightforward how to get it done on module abstraction level right away, so I wanted to practice how it could be done in hardcoded way with resources before moving to implementing it in a module.
# # "matcher" and "path" properties of health_check block are not supported for TCP protocol, so I use TCP protocol for target group and HTTP protocol for health check. 
# # It took some time fiddling to avoid "Protocol mismatch" errors from AWS API, so I want to same it here for future reference.

# resource "aws_lb" "app" {
#   name                             = "test"
#   internal                         = false
#   load_balancer_type               = "network"
#   security_groups                  = [ aws_security_group.this.id ] 
#   subnets                          = [ for subnet in module.vpc["10.0.0.0/16"].public_subnets : subnet.id ]
#   drop_invalid_header_fields       = true
#   # enable_cross_zone_load_balancing = true # For application load balancer this feature is always enabled (true) and cannot be disabled
#   # enable_deletion_protection = true
# }

# resource "aws_lb_target_group" "http" {
#   name                 = "test-http-tg"
#   port                 = 80
#   protocol             = "TCP"
#   vpc_id               = module.vpc["10.0.0.0/16"].vpc_id
#   deregistration_delay = 300

#   health_check {
#     healthy_threshold   = 3
#     interval            = 60
#     matcher             = "200"
#     path                = "/-/readiness"
#     protocol            = "HTTP"
#     timeout             = 30
#     unhealthy_threshold = 3
#   }

#   stickiness {
#     type            = "source_ip"
#     cookie_duration = 86400
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.app.arn
#   port              = 80
#   protocol          = "TCP"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.http.arn
#   }
# }

# resource "aws_lb_target_group" "ssh" {
#   name                 = "test-ssh-tg"
#   port                 = 22
#   protocol             = "TCP"
#   vpc_id               = module.vpc["10.0.0.0/16"].vpc_id
#   deregistration_delay = 300

#   health_check {
#     healthy_threshold   = 3
#     interval            = 60
#     protocol            = "TCP"
#     timeout             = 30
#     unhealthy_threshold = 3
#   }

#   stickiness {
#     type            = "source_ip"
#     cookie_duration = 86400
#   }
# }

# resource "aws_lb_listener" "ssh" {
#   load_balancer_arn = aws_lb.app.arn
#   port              = 22
#   protocol          = "TCP"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.ssh.arn
#   }
# }

# resource "aws_security_group" "this" {
#   name        = "test-lb-sg"
#   description = "security group for loadbalancer"
#   vpc_id      = module.vpc["10.0.0.0/16"].vpc_id
# }