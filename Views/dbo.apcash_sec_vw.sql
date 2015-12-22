SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









                                                
                                               


CREATE   VIEW [dbo].[apcash_sec_vw] AS
SELECT cash_acct_code, bank_name, org_id, check_num_mask, nat_cur_code FROM apcash WHERE 
org_id IN (SELECT organization_id from Organization)




GO
GRANT REFERENCES ON  [dbo].[apcash_sec_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apcash_sec_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apcash_sec_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apcash_sec_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apcash_sec_vw] TO [public]
GO
