SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[adm_cca_get_pubkey] as
begin
declare @pubkey varchar(255)

select @pubkey = isnull((select pub_key
from CVO_Control..ccakeys),'')

select @pubkey
end

GO
GRANT EXECUTE ON  [dbo].[adm_cca_get_pubkey] TO [public]
GO
