SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_cleanup_text_sp] as
-- /* exec cvo_cleanup_text_sp
update inv_master with (rowlock) set description = dbo.cvo_fn_rem_crlf(description)
where description <> dbo.cvo_fn_rem_crlf(description)

--select * from inv_master where description <> dbo.cvo_fn_rem_crlf(description)
--go
update pur_list with (rowlock) set description = dbo.cvo_fn_rem_crlf(description)
where description <> dbo.cvo_fn_rem_crlf(description)

--select * from pur_list where description <> dbo.cvo_fn_rem_crlf(description)
--go
update apvodet with (rowlock) set line_desc = dbo.cvo_fn_rem_crlf(line_desc)
where line_desc <> dbo.cvo_fn_rem_crlf(line_desc)

--select * from apvodet where line_desc <> dbo.cvo_fn_rem_crlf(line_desc)
--go
update armaster with (rowlock) set address_name = dbo.cvo_fn_rem_crlf(address_name)
where address_name <> dbo.cvo_fn_rem_crlf(address_name)

--select * from armaster where address_name <> dbo.cvo_fn_rem_crlf(address_name)
--go
update armaster with (rowlock) set addr1 = dbo.cvo_fn_rem_crlf(addr1)
where addr1 <> dbo.cvo_fn_rem_crlf(addr1)

--select * from armaster where addr1 <> dbo.cvo_fn_rem_crlf(addr1)
--go

update armaster with (rowlock) set addr2 = dbo.cvo_fn_rem_crlf(addr2)
where addr2 <> dbo.cvo_fn_rem_crlf(addr2)

--select * from armaster where addr2 <> dbo.cvo_fn_rem_crlf(addr2)
--go

update armaster with (rowlock) set addr3 = dbo.cvo_fn_rem_crlf(addr3)
where addr3 <> dbo.cvo_fn_rem_crlf(addr3)

--select * from armaster where addr3 <> dbo.cvo_fn_rem_crlf(addr3)
--go

update armaster with (rowlock) set addr4 = dbo.cvo_fn_rem_crlf(addr4)
where addr4 <> dbo.cvo_fn_rem_crlf(addr4)

--select * from armaster where addr4 <> dbo.cvo_fn_rem_crlf(addr4)
--go

update armaster with (rowlock) set addr5 = dbo.cvo_fn_rem_crlf(addr5)
where addr5 <> dbo.cvo_fn_rem_crlf(addr5)

--select * from armaster where addr5 <> dbo.cvo_fn_rem_crlf(addr5)
--go

update armaster with (rowlock) set addr6 = dbo.cvo_fn_rem_crlf(addr6)
where addr6 <> dbo.cvo_fn_rem_crlf(addr6)

--select * from armaster where addr6 <> dbo.cvo_fn_rem_crlf(addr6)
--go

--*/

GO
GRANT EXECUTE ON  [dbo].[cvo_cleanup_text_sp] TO [public]
GO
