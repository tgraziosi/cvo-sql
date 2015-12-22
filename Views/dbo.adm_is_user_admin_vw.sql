SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[adm_is_user_admin_vw] as
select h.group_id, h.id
  FROM CVO_Control..smgrphdr h
  INNER JOIN smgrpdet_vw d ON h.group_id = d.group_id and d.domain_username = SUSER_SNAME() AND ISNULL(h.global_flag,0)=1
union 
select h.group_id, h.id
  from CVO_Control..smgrphdr h
  INNER JOIN smgrpdet_vw d ON h.group_id = d.group_id
  INNER JOIN smspiduser_vw p ON d.domain_username = p.user_name and  p.spid = @@spid AND ISNULL(h.global_flag,0)=1
GO
GRANT REFERENCES ON  [dbo].[adm_is_user_admin_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_is_user_admin_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_is_user_admin_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_is_user_admin_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_is_user_admin_vw] TO [public]
GO
