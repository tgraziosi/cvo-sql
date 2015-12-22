SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_currency_info]

AS
select currency_code, symbol, position, curr_precision,
 neg_num_format, currency_mask from 
 CVO_Control..mccurr

GO
GRANT EXECUTE ON  [dbo].[cc_get_currency_info] TO [public]
GO
