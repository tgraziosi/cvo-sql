CREATE TABLE [dbo].[tdc_dist_next_serial_num]
(
[serial_no] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_dnsn1_idx] ON [dbo].[tdc_dist_next_serial_num] ([serial_no]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_dist_next_serial_num] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_dist_next_serial_num] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_dist_next_serial_num] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_dist_next_serial_num] TO [public]
GO
