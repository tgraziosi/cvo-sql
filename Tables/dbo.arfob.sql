CREATE TABLE [dbo].[arfob]
(
[timestamp] [timestamp] NOT NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fob_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dlvry_code] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_ARFOB_iu_trg] ON [dbo].[arfob] FOR insert,update
AS
begin

  DECLARE @nResult              int, 
	  @vcShippingTerm_ID    varchar(8), 
	  @last_ShippingTerm_ID varchar(8),  
	  @ddid                 varchar(32),
	  @Sender 		varchar(32) 
	
  if exists(select * from master..sysprocesses 
	      where spid=@@SPID and program_name = 'Epicor EAI')
    return

  select @last_ShippingTerm_ID = ''

  select @Sender = ddid
  from smcomp_vw

  while 1=1
  begin

    set rowcount 1
    select @vcShippingTerm_ID = fob_code, @ddid = ddid
    from inserted
    where fob_code > @last_ShippingTerm_ID
    order by fob_code

    if @@ROWCOUNT <= 0 
      BREAK
    
    set rowcount 0

    IF @ddid IS NULL
    BEGIN
	SELECT @ddid = REPLACE(CONVERT(varchar(36),NEWID()),'-','')

	UPDATE arfob
    	SET    ddid = @ddid
    	WHERE  arfob.fob_code = @vcShippingTerm_ID
    END

    exec @nResult = EAI_Send_sp @type = 'ShippingTerm', @data = @ddid, @source = 'BO', @action = 1, @SenderID = @Sender

    select @last_ShippingTerm_ID = @vcShippingTerm_ID
  end
end
GO
CREATE NONCLUSTERED INDEX [EAI_Integration] ON [dbo].[arfob] ([ddid]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arfob_ind_0] ON [dbo].[arfob] ([fob_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arfob] TO [public]
GO
GRANT SELECT ON  [dbo].[arfob] TO [public]
GO
GRANT INSERT ON  [dbo].[arfob] TO [public]
GO
GRANT DELETE ON  [dbo].[arfob] TO [public]
GO
GRANT UPDATE ON  [dbo].[arfob] TO [public]
GO
