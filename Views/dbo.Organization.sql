SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[Organization]
			AS
			SELECT 	timestamp, organization_id, organization_name, active_flag, outline_num, branch_account_number, 
				new_flag, create_date, create_username, last_change_date, last_change_username, 
				addr1, addr2, addr3, addr4, addr5, addr6, city, state, postal_code, country, tax_id_num, 
				region_flag, inherit_security, inherit_setup, tc_companycode 
			FROM Organization_all
GO
GRANT REFERENCES ON  [dbo].[Organization] TO [public]
GO
GRANT SELECT ON  [dbo].[Organization] TO [public]
GO
GRANT INSERT ON  [dbo].[Organization] TO [public]
GO
GRANT DELETE ON  [dbo].[Organization] TO [public]
GO
GRANT UPDATE ON  [dbo].[Organization] TO [public]
GO
