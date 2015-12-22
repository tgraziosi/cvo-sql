SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
                                      CREATE VIEW [dbo].[appayto] AS SELECT  timestamp,  vendor_code, 
 pay_to_code,  pay_to_name = address_name,  pay_to_short_name = short_name,  addr1, 
 addr2,  addr3,  addr4,  addr5,  addr6,  addr_sort1,  addr_sort2,  addr_sort3,  status_type, 
 attention_name,  attention_phone,  contact_name,  contact_phone,  tlx_twx,  phone_1, 
 phone_2,  tax_code,  terms_code,  fob_code,  posting_code,  location_code,  orig_zone_code, 
 comment_code,  address_type,  flag_1099,  tax_id_num,  rate_type_home,  rate_type_oper, 
 nat_cur_code,  one_cur_vendor,  city,  state,  postal_code,  country,  freight_code, 
 url,  note,    country_code,     ftp,  attention_email,  contact_email, extended_name,check_extendedname_flag FROM apmaster 
WHERE address_type = 1 
GO
GRANT REFERENCES ON  [dbo].[appayto] TO [public]
GO
GRANT SELECT ON  [dbo].[appayto] TO [public]
GO
GRANT INSERT ON  [dbo].[appayto] TO [public]
GO
GRANT DELETE ON  [dbo].[appayto] TO [public]
GO
GRANT UPDATE ON  [dbo].[appayto] TO [public]
GO
