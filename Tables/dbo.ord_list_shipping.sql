CREATE TABLE [dbo].[ord_list_shipping]
(
[timestamp] [timestamp] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[tracking_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NULL,
[no_cartons] [int] NULL,
[who_shipped] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[ord_list_shipping_del] ON [dbo].[ord_list_shipping]   FOR DELETE  AS 
BEGIN

declare	@order_no	int,
	@order_ext	int,
	@order_line	int,
	@parent_line	int,
	@row_no		int
declare	@pn		varchar(30),
	@loc		varchar(10),
	@shipto		varchar(10)


-- Get the first record from the deleted table
select @row_no = IsNull((select min(row_id) from deleted), 0)
while @row_no > 0
begin
  -- Check to see if the order ext is non-zero.  If it is, this could
  -- be a multiple ship-to order.
  select @order_no = order_no, @order_ext = order_ext, @order_line = line_no
  from deleted where row_id = @row_no
  if @order_ext > 0
  begin
    -- We have a non-zero extension so check the status of the orders table 
    -- entry that has the same order number but a zero extension.
    if 	(select status 
	from orders_all 
	where 	order_no = @order_no and
		ext = 0 )= 'L'
    begin
	-- The status is 'L' which indicates that the line being deleted in
	-- ord_list_shipping is for a child order of a multiple ship-to.  We need
	-- to find the line number of the parent order which relates to this
	-- child order and delete the same ord_list_shipping record for that line also.
	select @pn = part_no, @loc = location, @shipto = ship_to from ord_list
	where	( order_no = @order_no ) and
		( order_ext = @order_ext ) and
		( line_no = @order_line )

	-- The unique relationship between the parent order line no and the child
	-- order line no is established by the item no/location/ship-to columns.
	select @parent_line = isNull(line_no, 0) from ord_list
	where	( order_no = @order_no ) and
		( order_ext = 0 ) and
		( part_no = @pn ) and
		( location = @loc ) and
		( ship_to = @shipto )

	if @parent_line > 0
	begin
	  delete ord_list_shipping from deleted d 
	  where ( ord_list_shipping.order_no = @order_no ) and
		( ord_list_shipping.order_ext = 0 ) and
		( ord_list_shipping.line_no = @parent_line ) and
		( ord_list_shipping.tracking_no = d.tracking_no ) and
		( ord_list_shipping.date_shipped = d.date_shipped ) and
		( ord_list_shipping.who_shipped = d.who_shipped )and
		( d.row_id = @row_no )
	end

    end
  end
  -- Get the next record from deleted (if more than one)
  select @row_no = IsNull((select min(row_id) from deleted
			where row_id > @row_no), 0)
end

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[ord_list_shipping_ins] ON [dbo].[ord_list_shipping]   FOR INSERT  AS 
BEGIN

declare	@order_no	int,
	@order_ext	int,
	@order_line	int,
	@parent_line	int,
	@row_no		int
declare	@pn		varchar(30),
	@loc		varchar(10),
	@shipto		varchar(10)


-- Get the first record from the inserted table
select @row_no = IsNull((select min(row_id) from inserted), 0)
while @row_no > 0
begin
  -- Check to see if the order ext is non-zero.  If it is, this could
  -- be a multiple ship-to order.
  select @order_no = order_no, @order_ext = order_ext, @order_line = line_no
  from inserted where row_id = @row_no
  if @order_ext > 0
  begin
    -- We have a non-zero extension so check the status of the orders table 
    -- entry that has the same order number but a zero extension.
    if 	(select status 
	from orders_all 
	where 	order_no = @order_no and
		ext = 0 )= 'L'
    begin
	-- The status is 'L' which indicates that the line being inserted into
	-- ord_list_shipping is for a child order of a multiple ship-to.  We need
	-- to find the line number of the parent order which relates to this
	-- child order and insert the same information for that line.
	select @pn = part_no, @loc = location, @shipto = ship_to from ord_list
	where	( order_no = @order_no ) and
		( order_ext = @order_ext ) and
		( line_no = @order_line )

	-- The unique relationship between the parent order line no and the child
	-- order line no is established by the item no/location/ship-to columns.
	select @parent_line = line_no from ord_list
	where	( order_no = @order_no ) and
		( order_ext = 0 ) and
		( part_no = @pn ) and
		( location = @loc ) and
		( ship_to = @shipto )

	insert ord_list_shipping (order_no, order_ext, line_no,
		tracking_no, date_shipped, who_shipped)
		select @order_no, 0, @parent_line,
		tracking_no, date_shipped, who_shipped
		from inserted 
		where row_id = @row_no

    end
  end
  -- Get the next record from inserted (if more than one)
  select @row_no = IsNull((select min(row_id) from inserted
			where row_id > @row_no), 0)
end

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[ord_list_shipping_upd] ON [dbo].[ord_list_shipping]   FOR UPDATE  AS 
BEGIN

declare	@order_no	int,
	@order_ext	int,
	@order_line	int,
	@parent_line	int,
	@row_no		int
declare	@pn		varchar(30),
	@loc		varchar(10),
	@shipto		varchar(10)


-- Get the first record from the inserted table
select @row_no = IsNull((select min(row_id) from inserted), 0)
while @row_no > 0
begin
  -- Check to see if the order ext is non-zero.  If it is, this could
  -- be a multiple ship-to order.
  select @order_no = order_no, @order_ext = order_ext, @order_line = line_no
  from inserted where row_id = @row_no
  if @order_ext > 0
  begin
    -- We have a non-zero extension so check the status of the orders table 
    -- entry that has the same order number but a zero extension.
    if 	(select status 
	from orders_all 
	where 	order_no = @order_no and
		ext = 0 )= 'L'
    begin
	-- The status is 'L' which indicates that the line being updated in
	-- ord_list_shipping is for a child order of a multiple ship-to.  We need
	-- to find the line number of the parent order which relates to this
	-- child order and update the same information for that line.
	select @pn = part_no, @loc = location, @shipto = ship_to from ord_list
	where	( order_no = @order_no ) and
		( order_ext = @order_ext ) and
		( line_no = @order_line )

	-- The unique relationship between the parent order line no and the child
	-- order line no is established by the item no/location/ship-to columns.
	select @parent_line = isNull(line_no, 0) from ord_list
	where	( order_no = @order_no ) and
		( order_ext = 0 ) and
		( part_no = @pn ) and
		( location = @loc ) and
		( ship_to = @shipto )

	if @parent_line > 0
	begin
	  update ord_list_shipping
	  set ord_list_shipping.tracking_no = i.tracking_no, 
		ord_list_shipping.date_shipped = i.date_shipped,
	  	ord_list_shipping.who_shipped = i.who_shipped
	  from inserted i, deleted d
	  where ( i.row_id = @row_no ) and
		( d.row_id = @row_no ) and
		( ord_list_shipping.tracking_no = d.tracking_no ) and
		( ord_list_shipping.date_shipped = d.date_shipped ) and
		( ord_list_shipping.who_shipped = d.who_shipped )
	end

    end
  end
  -- Get the next record from inserted (if more than one)
  select @row_no = IsNull((select min(row_id) from inserted
			where row_id > @row_no), 0)
end

END
GO
CREATE NONCLUSTERED INDEX [ordlstshipm1] ON [dbo].[ord_list_shipping] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ord_list_shipping_pk] ON [dbo].[ord_list_shipping] ([row_id], [order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ord_list_shipping] ADD CONSTRAINT [ord_list_shipping_ord_list_fk1] FOREIGN KEY ([order_no], [order_ext], [line_no]) REFERENCES [dbo].[ord_list] ([order_no], [order_ext], [line_no])
GO
GRANT REFERENCES ON  [dbo].[ord_list_shipping] TO [public]
GO
GRANT SELECT ON  [dbo].[ord_list_shipping] TO [public]
GO
GRANT INSERT ON  [dbo].[ord_list_shipping] TO [public]
GO
GRANT DELETE ON  [dbo].[ord_list_shipping] TO [public]
GO
GRANT UPDATE ON  [dbo].[ord_list_shipping] TO [public]
GO
