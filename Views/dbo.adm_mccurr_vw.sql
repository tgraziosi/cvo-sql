SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_mccurr_vw] as 
  select timestamp, currency_code, description, symbol, currency_mask, user_defined_mask, rounding_factor, curr_precision, position, neg_num_format, ddid
  from CVO_Control..mccurr_vw
GO
GRANT REFERENCES ON  [dbo].[adm_mccurr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_mccurr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_mccurr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_mccurr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_mccurr_vw] TO [public]
GO
