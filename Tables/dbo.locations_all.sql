CREATE TABLE [dbo].[locations_all]
(
[timestamp] [timestamp] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_type] [smallint] NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contact_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[consign_customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[consign_vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[aracct_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apacct_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dflt_recv_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[harbour] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bundesland] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[department] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_locations_insupd] ON [dbo].[locations_all]   FOR INSERT, UPDATE  AS 
BEGIN
	DECLARE @location_id varchar(10),
            @SenderID   varchar(32)

	Declare @send_document_flag char(1)  -- rev 3

	select @send_document_flag = 'N'
                     
	IF Exists( SELECT * 
		FROM 	config  
   		WHERE 	flag = 'EAI' and
			value_str = 'Y')
	BEGIN	--EAI enable
	
		IF ((Exists( select *
			from inserted i, deleted d
			where 	(i.location <> d.location) or 
				(i.name <> d.name) or 
				(i.addr1 <> d.addr1) or 
				(i.addr2 <> d.addr2) or 
				(i.addr3 <> d.addr3) or 
				(i.addr4 <> d.addr4) or
				(i.addr5 <> d.addr5) or
				(i.contact_name <> d.contact_name) or 
				(i.phone <> d.phone) or 
				(i.note <> d.note) or 
				(i.void <> d.void))) or (not exists( select 'X' from deleted )))
			
		BEGIN	--Location has been changed, send data to Front Office
			select @send_document_flag = 'Y'
		END else begin
			If Update(location) or Update(name) or Update(addr1) or Update(addr2) or Update(addr3) or
			   Update(addr4) or Update(addr5) or Update(contact_name) or Update(phone) or Update(note)
			   or Update(void) begin
				select @send_document_flag = 'Y'
			end
		END

		If @send_document_flag = 'Y' begin

			select @SenderID = ddid 
			from smcomp_vw

			--Case of Update or insert
			select @location_id = isnull((select min(location) from inserted),'')

			while @location_id <> '' 	--while loop for customer
			begin
				if (@location_id > '')
					exec EAI_Send_sp 'location', @location_id, 'BO', 0,  @SenderID

				--Get the next location
				select @location_id = isnull((select min(location) 
						from inserted
						where location > @location_id),'')
			END	--End while loop
		END
	END
END


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[locations_insert_trg] ON [dbo].[locations_all] FOR INSERT AS 
BEGIN

DECLARE @i_location varchar(10), @i_name varchar(30), @i_location_type smallint,
@i_addr1 varchar(40), @i_addr2 varchar(40), @i_addr3 varchar(40), @i_addr4 varchar(40),
@i_addr5 varchar(40), @i_addr_sort1 varchar(40), @i_addr_sort2 varchar(40),
@i_addr_sort3 varchar(40), @i_phone varchar(30), @i_contact_name varchar(30),
@i_consign_customer_code varchar(8), @i_consign_vendor_code varchar(12),
@i_aracct_code varchar(8), @i_zone_code varchar(8), @i_void char(1), @i_void_who varchar(20),
@i_void_date datetime, @i_note varchar(255), @i_apacct_code varchar(8),
@i_dflt_recv_bin varchar(12), @i_country_code varchar(3), @i_harbour varchar(4),
@i_bundesland varchar(2), @i_department varchar(2), @i_organization_id varchar(30)

declare @locationid int

DECLARE t700INSloca_cursor CURSOR LOCAL STATIC FOR 
SELECT i.location, i.name, i.location_type, i.addr1, i.addr2, i.addr3, i.addr4, i.addr5,
i.addr_sort1, i.addr_sort2, i.addr_sort3, i.phone, i.contact_name, i.consign_customer_code,
i.consign_vendor_code, i.aracct_code, i.zone_code, i.void, i.void_who, i.void_date, i.note,
i.apacct_code, i.dflt_recv_bin, i.country_code, i.harbour, i.bundesland, i.department,
i.organization_id
from inserted i

OPEN t700INSloca_cursor

if @@cursor_rows = 0
begin
CLOSE t700INSloca_cursor
DEALLOCATE t700INSloca_cursor
return
end

FETCH NEXT FROM t700INSloca_cursor into
@i_location, @i_name, @i_location_type, @i_addr1, @i_addr2, @i_addr3, @i_addr4, @i_addr5,
@i_addr_sort1, @i_addr_sort2, @i_addr_sort3, @i_phone, @i_contact_name,
@i_consign_customer_code, @i_consign_vendor_code, @i_aracct_code, @i_zone_code, @i_void,
@i_void_who, @i_void_date, @i_note, @i_apacct_code, @i_dflt_recv_bin, @i_country_code,
@i_harbour, @i_bundesland, @i_department, @i_organization_id

While @@FETCH_STATUS = 0
begin
select @locationid = isnull((select max(LOCATIONID) from EFORECAST_LOCATION),0) + 1
insert EFORECAST_LOCATION ( LOCATIONID, LOCATION_NAME , 
			LOCATION ,  
			SESSIONID )
select @locationid, @i_location, @i_location , 0

if @@error <>0 
  begin
	rollback tran
	exec adm_raiserror 91353, 'Error inserting a record in EFORECAST_LOCATION'
  end


FETCH NEXT FROM t700INSloca_cursor into
@i_location, @i_name, @i_location_type, @i_addr1, @i_addr2, @i_addr3, @i_addr4, @i_addr5,
@i_addr_sort1, @i_addr_sort2, @i_addr_sort3, @i_phone, @i_contact_name,
@i_consign_customer_code, @i_consign_vendor_code, @i_aracct_code, @i_zone_code, @i_void,
@i_void_who, @i_void_date, @i_note, @i_apacct_code, @i_dflt_recv_bin, @i_country_code,
@i_harbour, @i_bundesland, @i_department, @i_organization_id
end -- while

CLOSE t700INSloca_cursor
DEALLOCATE t700INSloca_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO











CREATE TRIGGER [dbo].[locations_integration_del_trg]
	ON [dbo].[locations_all]
	FOR DELETE AS
BEGIN
	INSERT INTO epintegrationrecs SELECT location, 3, '', 'D', 0 FROM Deleted
END

GO
DISABLE TRIGGER [dbo].[locations_integration_del_trg] ON [dbo].[locations_all]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO











CREATE TRIGGER [dbo].[locations_integration_ins_trg]
	ON [dbo].[locations_all]
	FOR INSERT AS
BEGIN
	INSERT INTO epintegrationrecs SELECT location, '', 3, 'I', 0 FROM Inserted
END

GO
DISABLE TRIGGER [dbo].[locations_integration_ins_trg] ON [dbo].[locations_all]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO











CREATE TRIGGER [dbo].[locations_integration_upd_trg]
	ON [dbo].[locations_all]
	FOR UPDATE AS
BEGIN	
	DELETE epintegrationrecs WHERE action = 'U' AND type = 3 AND id_code IN ( SELECT location FROM Inserted )
	INSERT INTO epintegrationrecs SELECT location, '', 3, 'U', 0 FROM Inserted
END

GO
DISABLE TRIGGER [dbo].[locations_integration_upd_trg] ON [dbo].[locations_all]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[t500delloc] ON [dbo].[locations_all] 
 FOR DELETE 
AS
begin
if exists (select * from config where flag='TRIG_DEL_LOC' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 73499 ,'You Can Not Delete A LOCATION!' 
	return
	end
end


GO
CREATE UNIQUE CLUSTERED INDEX [loc1] ON [dbo].[locations_all] ([location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [loc2] ON [dbo].[locations_all] ([name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[locations_all] TO [public]
GO
GRANT SELECT ON  [dbo].[locations_all] TO [public]
GO
GRANT INSERT ON  [dbo].[locations_all] TO [public]
GO
GRANT DELETE ON  [dbo].[locations_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[locations_all] TO [public]
GO
