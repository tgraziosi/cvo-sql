SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC cvo_cc_discount_history_sp '042114'

CREATE PROC [dbo].[cvo_cc_discount_history_sp] @customer_code varchar(8)    
AS  
BEGIN

	SELECT distinct	CONVERT(varchar(25), a.audit_date, 100) audit_date,
		 replace(isnull((select top 1 domain_username from smusers_vw s (nolock)
		 where a.user_id = cast(s.user_id as varchar(50))), isnull(a.user_id,'')),'cvoptical\','') as user_id,
		ISNULL(a.field_from,'') field_from,
			ISNULL(a.field_to,'') field_to,
			CASE a.movement_flag 
				WHEN 1 THEN 'Price Code set to ' + ISNULL(c.description,'') + '.'
				WHEN 2 THEN 'Price Code changed from ' + ISNULL(b.description,'') + ' to ' + ISNULL(c.description,'') + '.'
				ELSE '' END
	FROM	cvoarmasteraudit a (NOLOCK)
	LEFT JOIN arprice b (NOLOCK)
	ON		a.field_from = b.price_code
	LEFT JOIN arprice c (NOLOCK)
	ON		a.field_to = c.price_code
	WHERE	a.customer_code = @customer_code
	AND		a.field_name = 'price_code'
	ORDER BY CONVERT(varchar(25), a.audit_date, 100) DESC


END
GO
GRANT EXECUTE ON  [dbo].[cvo_cc_discount_history_sp] TO [public]
GO
