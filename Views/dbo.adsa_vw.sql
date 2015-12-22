SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[adsa_vw]
AS
SELECT 
	service_agreement.item_id, 
	description, call_based, 
    	time_based, 
	contract_length, 	
	verify_reg_flag, 
    	allow_neg_units_flag, 
	unltd_units_flag, 
	use_mult_flag, 
    	void_flag, 
	void_date, 
	void_who, 
	service_agreement_price.price,

	x_contract_length = contract_length,
	x_void_date = ((datediff(day, '01/01/1900', void_date) + 693596)) + (datepart(hh,void_date)*.01 + datepart(mi,void_date)*.0001 + datepart(ss,void_date)*.000001),
	x_price = service_agreement_price.price


FROM 
	service_agreement, 
	service_agreement_price, 
	glco
WHERE 
	service_agreement.item_id = service_agreement_price.item_id AND 
	glco.home_currency = service_agreement_price.curr_code



/**/
GO
GRANT REFERENCES ON  [dbo].[adsa_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adsa_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adsa_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adsa_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adsa_vw] TO [public]
GO
