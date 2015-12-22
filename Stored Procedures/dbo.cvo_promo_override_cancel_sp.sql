SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_promo_override_cancel_sp] (@order_no int, @ext int)

-- exec cvo_promo_override_cancel_sp 2106569,	0

as 
begin
set nocount on

update dbo.cvo_promo_override_audit set order_ext = 99 where order_no = @order_no and order_ext = @ext
and order_ext <> 99
if @@rowcount <> 0  select 'Promo Override Cancelled'
    else select 'Promo Override NOT Cancelled'

end
GO
GRANT EXECUTE ON  [dbo].[cvo_promo_override_cancel_sp] TO [public]
GO
