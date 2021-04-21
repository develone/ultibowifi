unit wifidevice;

{$mode objfpc}{$H+}


interface

uses
  mmc,
  Classes, SysUtils, Devices,
  GlobalConfig,GlobalConst,GlobalTypes,Platform,Threads,DMA,gpio;

const
  IOCTL_MAX_BLKLEN = 2048;
  SDPCM_HEADER_SIZE = 8;

  // wifi control commands
  WLC_GET_VAR = 262;
  WLC_SET_VAR = 263;

  WHD_MSG_IFNAME_MAX = 16;

  ETHER_ADDR_LEN = 6;
  BSS_TYPE_ANY = 2;
  SCAN_TYPE_PASSIVE = 1;
  SSID_MAX_LEN = 32;
  WLC_E_LAST = 152;
  WL_EVENTING_MASK_LEN = (WLC_E_LAST + 7) div 8;
  MCSSET_LEN = 16;
  DOT11_IE_ID_RSN = 48;



  BUS_FUNCTION = 0;
  BACKPLANE_FUNCTION = 1;
  WLAN_FUNCTION = 2;

  RECEIVE_BUFFER_DEFAULT_BLOCK_SIZE = 512;
  WLC_SET_PASSIVE_SCAN = 49;

  // sdio core regs
  Intstatus	= $20;
  	Fcstate		= 1 shl 4;
  	Fcchange	= 1 shl 5;
  	FrameInt	= 1 shl 6;
  	MailboxInt	= 1 shl 7;
  Intmask		= $24;
  Sbmbox		= $40;
  Sbmboxdata	= $48;
  Hostmboxdata= $4c;
  Fwready = $80;

  Gpiopullup	= $58;
  Gpiopulldown	= $5c;
  Chipctladdr	= $650;
  Chipctldata	= $654;

  Pullups	= $1000f;



  FIRMWARE_CHUNK_SIZE = 2048;
  FIRWMARE_OPTIONS_COUNT = 7;
  FIRMWARE_FILENAME_ROOT = 'c:\firmware\';

  {SDIO Bus Speeds (Hz)}
  SDIO_BUS_SPEED_DEFAULT   = 0;
  SDIO_BUS_SPEED_HS26      = 26000000;
  SDIO_BUS_SPEED_HS52      = 52000000;
  SDIO_BUS_SPEED_DDR       = 52000000;
  SDIO_BUS_SPEED_HS          = 50000000;
  SDIO_BUS_SPEED_HS200     = 200000000;

  WLAN_ON_PIN = GPIO_PIN_41;
  SD_32KHZ_PIN = GPIO_PIN_43;

  {MMC logging}
  SDHCI_LOG_LEVEL_DEBUG     = LOG_LEVEL_DEBUG;  {SDHCI debugging messages}
  SDHCI_LOG_LEVEL_INFO      = LOG_LEVEL_INFO;   {SDHCI informational messages, such as a device being attached or detached}
  SDHCI_LOG_LEVEL_WARN      = LOG_LEVEL_WARN;   {SDHCI warning messages}
  SDHCI_LOG_LEVEL_ERROR     = LOG_LEVEL_ERROR;  {SDHCI error messages}
  SDHCI_LOG_LEVEL_NONE      = LOG_LEVEL_NONE;   {No SDHCI messages}

  {SDIO Device States}
  SDIO_STATE_EJECTED  = 0;
  SDIO_STATE_INSERTED = 1;

  SDIO_STATE_MAX      = 1;

  {Maximum block count for SDIO}
  SDIO_MAX_BLOCK_COUNT = 65535;

  {SDIO Modes} //To Do //These are really the capabilities flags for SDIO/SDHCI.Capabilities/PresetCapabilities  SDIO_CAP_
  SDIO_MODE_HS		= (1 shl 0);
  SDIO_MODE_HS_52MHz	= (1 shl 1);
  SDIO_MODE_4BIT		= (1 shl 2);
  SDIO_MODE_8BIT		= (1 shl 3);
  SDIO_MODE_SPI		= (1 shl 4);
  SDIO_MODE_HC		= (1 shl 5);
  SDIO_MODE_DDR_52MHz	= (1 shl 6);

  {SDHCI Host States}
  SDHCI_STATE_DISABLED = 0;
  SDHCI_STATE_ENABLED  = 1;

  SDHCI_STATE_MAX      = 1;


  {SDHCI specific constants}
  SDHCI_NAME_PREFIX = 'SDHCI';     {Name prefix for SDHCI Devices}

  {SDHCI Host Types}
  SDHCI_TYPE_NONE      = 0;
  SDHCI_TYPE_MMC       = 1; {An MMC specification host controller}
  SDHCI_TYPE_SD        = 2; {An SD specification host controller}
  SDHCI_TYPE_MMCI      = 3; {An MMCI specification host controller}

  SDHCI_TYPE_MAX       = 3;

  {SDHCI Type Names}
  SDHCI_TYPE_NAMES:array[SDHCI_TYPE_NONE..SDHCI_TYPE_MAX] of String = (
   'SDHCI_TYPE_NONE',
   'SDHCI_TYPE_MMC',
   'SDHCI_TYPE_SD',
   'SDHCI_TYPE_MMCI');


  {SDHCI State Names}
  SDHCI_STATE_NAMES:array[SDHCI_STATE_DISABLED..SDHCI_STATE_MAX] of String = (
   'SDHCI_STATE_DISABLED',
   'SDHCI_STATE_ENABLED');

  {SDHCI Host Flags}
  SDHCI_FLAG_NONE          = $00000000;
  SDHCI_FLAG_SDMA          = $00000001;
  SDHCI_FLAG_ADMA          = $00000002;
  SDHCI_FLAG_SPI           = $00000004;
  SDHCI_FLAG_CRC_ENABLE    = $00000008;
  SDHCI_FLAG_NON_STANDARD  = $00000010; {Host Controller uses a non standard interface (not supporting SDHCI register layout)}
  SDHCI_FLAG_AUTO_CMD12    = $00000020; {Host Controller supports Auto CMD12 (Stop Transmission)}
  SDHCI_FLAG_AUTO_CMD23    = $00000040; {Host Controller supports Auto CMD23 (Set Block Count)}
  //To Do //More //DMA shared, DMA align etc


  {SDIO Directions} //To Do //??
  SDIO_DATA_READ		= 1;
  SDIO_DATA_WRITE		= 2;

  {SDIO Response Types (From: /include/linux/mmc/mmc.h)}
  {Native}
  SDIO_RSP_PRESENT = (1 shl 0);
  SDIO_RSP_136	 = (1 shl 1); {136 bit response}
  SDIO_RSP_CRC	 = (1 shl 2); {Expect valid crc}
  SDIO_RSP_BUSY	 = (1 shl 3); {Card may send busy}
  SDIO_RSP_OPCODE	 = (1 shl 4); {Response contains opcode}

  {These are the native response types, and correspond to valid bit patterns of the above flags. One additional valid pattern is all zeros, which means we don't expect a respons}
  SDIO_RSP_NONE	= (0);
  SDIO_RSP_R1	    = (SDIO_RSP_PRESENT or SDIO_RSP_CRC or SDIO_RSP_OPCODE);
  SDIO_RSP_R1B    = (SDIO_RSP_PRESENT or SDIO_RSP_CRC or SDIO_RSP_OPCODE or SDIO_RSP_BUSY);
  SDIO_RSP_R2	    = (SDIO_RSP_PRESENT or SDIO_RSP_136 or SDIO_RSP_CRC);
  SDIO_RSP_R3	    = (SDIO_RSP_PRESENT);
  SDIO_RSP_R4	    = (SDIO_RSP_PRESENT);
  SDIO_RSP_R5	    = (SDIO_RSP_PRESENT or SDIO_RSP_CRC or SDIO_RSP_OPCODE);
  SDIO_RSP_R6	    = (SDIO_RSP_PRESENT or SDIO_RSP_CRC or SDIO_RSP_OPCODE);
  SDIO_RSP_R7	    = (SDIO_RSP_PRESENT or SDIO_RSP_CRC or SDIO_RSP_OPCODE);


  {SDHCI Voltage Values}
  SDHCI_VDD_165_195	= $00000080; {VDD voltage 1.65 - 1.95}
  SDHCI_VDD_20_21		= $00000100; {VDD voltage 2.0 ~ 2.1}
  SDHCI_VDD_21_22		= $00000200; {VDD voltage 2.1 ~ 2.2}
  SDHCI_VDD_22_23		= $00000400; {VDD voltage 2.2 ~ 2.3}
  SDHCI_VDD_23_24		= $00000800; {VDD voltage 2.3 ~ 2.4}
  SDHCI_VDD_24_25		= $00001000; {VDD voltage 2.4 ~ 2.5}
  SDHCI_VDD_25_26		= $00002000; {VDD voltage 2.5 ~ 2.6}
  SDHCI_VDD_26_27		= $00004000; {VDD voltage 2.6 ~ 2.7}
  SDHCI_VDD_27_28		= $00008000; {VDD voltage 2.7 ~ 2.8}
  SDHCI_VDD_28_29		= $00010000; {VDD voltage 2.8 ~ 2.9}
  SDHCI_VDD_29_30		= $00020000; {VDD voltage 2.9 ~ 3.0}
  SDHCI_VDD_30_31		= $00040000; {VDD voltage 3.0 ~ 3.1}
  SDHCI_VDD_31_32		= $00080000; {VDD voltage 3.1 ~ 3.2}
  SDHCI_VDD_32_33		= $00100000; {VDD voltage 3.2 ~ 3.3}
  SDHCI_VDD_33_34		= $00200000; {VDD voltage 3.3 ~ 3.4}
  SDHCI_VDD_34_35		= $00400000; {VDD voltage 3.4 ~ 3.5}
  SDHCI_VDD_35_36		= $00800000; {VDD voltage 3.5 ~ 3.6}

  {SDHCI Controller Registers}
  SDHCI_DMA_ADDRESS	     = $00;
  SDHCI_BLOCK_SIZE	     = $04;
  SDHCI_BLOCK_COUNT	     = $06;
  SDHCI_ARGUMENT		     = $08;
  SDHCI_TRANSFER_MODE	 = $0C;
  SDHCI_COMMAND		     = $0E;
  SDHCI_RESPONSE		     = $10;
  SDHCI_BUFFER		     = $20;
  SDHCI_PRESENT_STATE	 = $24;
  SDHCI_HOST_CONTROL	     = $28;
  SDHCI_POWER_CONTROL	 = $29;
  SDHCI_BLOCK_GAP_CONTROL = $2A;
  SDHCI_WAKE_UP_CONTROL	 = $2B;
  SDHCI_CLOCK_CONTROL	 = $2C;
  SDHCI_TIMEOUT_CONTROL	 = $2E;
  SDHCI_SOFTWARE_RESET	 = $2F;
  SDHCI_INT_STATUS	     = $30;
  SDHCI_INT_ENABLE	     = $34;
  SDHCI_SIGNAL_ENABLE	 = $38;
  SDHCI_ACMD12_ERR	     = $3C;
  {3E-3F reserved}
  SDHCI_CAPABILITIES      = $40;
  SDHCI_CAPABILITIES_1	 = $44;
  SDHCI_MAX_CURRENT	     = $48;
  {4C-4F reserved for more max current}
  SDHCI_SET_ACMD12_ERROR	 = $50;
  SDHCI_SET_INT_ERROR	 = $52;
  SDHCI_ADMA_ERROR	     = $54;
  {55-57 reserved}
  SDHCI_ADMA_ADDRESS	     = $58;
  {60-FB reserved}
  SDHCI_SLOT_INT_STATUS	 = $FC;
  SDHCI_HOST_VERSION	     = $FE;

  {SDHCI Transfer Modes}
  SDHCI_TRNS_DMA		    = $01;
  SDHCI_TRNS_BLK_CNT_EN	= $02;
  SDHCI_TRNS_AUTO_CMD12	= $04;  {SDHCI_TRNS_ACMD12}
  SDHCI_TRNS_AUTO_CMD23	= $08;
  SDHCI_TRNS_READ	    = $10;
  SDHCI_TRNS_MULTI	    = $20;
  SDHCI_TRNS_R5	    = $40;

  {SDHCI Command Values}
  SDHCI_CMD_RESP_MASK = $03;
  SDHCI_CMD_CRC		 = $08;
  SDHCI_CMD_INDEX	 = $10;
  SDHCI_CMD_DATA		 = $20;
  SDHCI_CMD_ABORTCMD	 = $C0;

  {SDHCI Command Response Values}
  SDHCI_CMD_RESP_NONE	   = $00;
  SDHCI_CMD_RESP_LONG	   = $01;
  SDHCI_CMD_RESP_SHORT	   = $02;
  SDHCI_CMD_RESP_SHORT_BUSY = $03;

  {SDHCI Present State Values}
  SDHCI_CMD_INHIBIT	         = $00000001;
  SDHCI_DATA_INHIBIT	         = $00000002;
  SDHCI_DOING_WRITE	         = $00000100;
  SDHCI_DOING_READ	         = $00000200;
  SDHCI_SPACE_AVAILABLE	     = $00000400;
  SDHCI_DATA_AVAILABLE	     = $00000800;
  SDHCI_CARD_PRESENT	         = $00010000;
  SDHCI_CARD_STATE_STABLE	 = $00020000;
  SDHCI_CARD_DETECT_PIN_LEVEL = $00040000;
  SDHCI_WRITE_PROTECT	     = $00080000; {Set if Write Enabled / Clear if Write Protected}

  {SDHCI Host Control Values}
  SDHCI_CTRL_LED		    = $01;
  SDHCI_CTRL_4BITBUS	    = $02;
  SDHCI_CTRL_HISPD	    = $04;
  SDHCI_CTRL_DMA_MASK    = $18;
  SDHCI_CTRL_SDMA	    = $00;
  SDHCI_CTRL_ADMA1	    = $08;
  SDHCI_CTRL_ADMA32	    = $10;
  SDHCI_CTRL_ADMA64	    = $18;
  SDHCI_CTRL_8BITBUS 	= $20;
  SDHCI_CTRL_CD_TEST_INS = $40;
  SDHCI_CTRL_CD_TEST	    = $80;

  {SDHCI Power Control Values}
  SDHCI_POWER_ON		= $01;
  SDHCI_POWER_180	= $0A;
  SDHCI_POWER_300	= $0C;
  SDHCI_POWER_330	= $0E;

  {SDHCI Wakeup Control Values}
  SDHCI_WAKE_ON_INT	  = $01;
  SDHCI_WAKE_ON_INSERT = $02;
  SDHCI_WAKE_ON_REMOVE = $04;

  {SDHCI Clock Control Values}
  SDHCI_DIVIDER_SHIFT	= 8;
  SDHCI_DIVIDER_HI_SHIFT	= 6;
  SDHCI_DIV_MASK	        = $FF;
  SDHCI_DIV_MASK_LEN	    = 8;
  SDHCI_DIV_HI_MASK	    = $0300;
  SDHCI_CLOCK_CARD_EN	= $0004;
  SDHCI_CLOCK_INT_STABLE = $0002;
  SDHCI_CLOCK_INT_EN	    = $0001;

  {SDHCI Software Reset Values}
  SDHCI_RESET_ALL	= $01;
  SDHCI_RESET_CMD	= $02;
  SDHCI_RESET_DATA	= $04;

  {SDHCI Interrupt Values}
  SDHCI_INT_RESPONSE	    = $00000001;
  SDHCI_INT_DATA_END	    = $00000002;
  SDHCI_INT_BLK_GAP      = $00000004;
  SDHCI_INT_DMA_END	    = $00000008;
  SDHCI_INT_SPACE_AVAIL	= $00000010;
  SDHCI_INT_DATA_AVAIL	= $00000020;
  SDHCI_INT_CARD_INSERT	= $00000040;
  SDHCI_INT_CARD_REMOVE	= $00000080;
  SDHCI_INT_CARD_INT	    = $00000100;
  SDHCI_INT_ERROR	    = $00008000;
  SDHCI_INT_TIMEOUT	    = $00010000;
  SDHCI_INT_CRC		    = $00020000;
  SDHCI_INT_END_BIT	    = $00040000;
  SDHCI_INT_INDEX	    = $00080000;
  SDHCI_INT_DATA_TIMEOUT = $00100000;
  SDHCI_INT_DATA_CRC	    = $00200000;
  SDHCI_INT_DATA_END_BIT = $00400000;
  SDHCI_INT_BUS_POWER	= $00800000;
  SDHCI_INT_ACMD12ERR	= $01000000;
  SDHCI_INT_ADMA_ERROR	= $02000000;

  SDHCI_INT_NORMAL_MASK	= $00007FFF;
  SDHCI_INT_ERROR_MASK	= $FFFF8000;

  SDHCI_INT_CMD_MASK	    = (SDHCI_INT_RESPONSE or SDHCI_INT_TIMEOUT or SDHCI_INT_CRC or SDHCI_INT_END_BIT or SDHCI_INT_INDEX);
  SDHCI_INT_DATA_MASK	= (SDHCI_INT_DATA_END or SDHCI_INT_DMA_END or SDHCI_INT_DATA_AVAIL or SDHCI_INT_SPACE_AVAIL or SDHCI_INT_DATA_TIMEOUT or SDHCI_INT_DATA_CRC or SDHCI_INT_DATA_END_BIT or SDHCI_INT_ADMA_ERROR or SDHCI_INT_BLK_GAP);
  SDHCI_INT_ALL_MASK	    = (LongWord(-1));

  {SDHCI Capabilities Values}
  SDHCI_TIMEOUT_CLK_MASK	     = $0000003F;
  SDHCI_TIMEOUT_CLK_SHIFT     = 0;
  SDHCI_TIMEOUT_CLK_UNIT	     = $00000080;
  SDHCI_CLOCK_BASE_MASK	     = $00003F00;
  SDHCI_CLOCK_V3_BASE_MASK    = $0000FF00;
  SDHCI_CLOCK_BASE_SHIFT	     = 8;
  SDHCI_CLOCK_BASE_MULTIPLIER = 1000000;
  SDHCI_MAX_BLOCK_MASK	     = $00030000;
  SDHCI_MAX_BLOCK_SHIFT       = 16;
  SDHCI_CAN_DO_8BIT	         = $00040000;
  SDHCI_CAN_DO_ADMA2	         = $00080000;
  SDHCI_CAN_DO_ADMA1	         = $00100000;
  SDHCI_CAN_DO_HISPD	         = $00200000;
  SDHCI_CAN_DO_SDMA	         = $00400000;
  SDHCI_CAN_VDD_330	         = $01000000;
  SDHCI_CAN_VDD_300	         = $02000000;
  SDHCI_CAN_VDD_180	         = $04000000;
  SDHCI_CAN_64BIT	         = $10000000;

  {SDHCI Host Version Values}
  SDHCI_VENDOR_VER_MASK	= $FF00;
  SDHCI_VENDOR_VER_SHIFT	= 8;
  SDHCI_SPEC_VER_MASK	= $00FF;
  SDHCI_SPEC_VER_SHIFT	= 0;
  SDHCI_SPEC_100	        = 0;
  SDHCI_SPEC_200	        = 1;
  SDHCI_SPEC_300	        = 2;

  //SDHCI_GET_VERSION(x) (x->version and SDHCI_SPEC_VER_MASK);

  {SDHCI Clock Dividers}
  SDHCI_MAX_CLOCK_DIV_SPEC_200	 = 256;
  SDHCI_MAX_CLOCK_DIV_SPEC_300	 = 2046;

  {SDHCI Quirks/Bugs}
  {From: U-Boot sdhci.h}
  (*SDHCI_QUIRK_32BIT_DMA_ADDR	          = (1 shl 0); {See: SDHCI_QUIRK_32BIT_DMA_ADDR below}
  SDHCI_QUIRK_REG32_RW		          = (1 shl 1);
  SDHCI_QUIRK_BROKEN_R1B		          = (1 shl 2);
  SDHCI_QUIRK_NO_HISPD_BIT	          = (1 shl 3); {See: SDHCI_QUIRK_NO_HISPD_BIT below}
  SDHCI_QUIRK_BROKEN_VOLTAGE	          = (1 shl 4); {Use  SDHCI_QUIRK_MISSING_CAPS instead}
  SDHCI_QUIRK_NO_CD		              = (1 shl 5); {See: SDHCI_QUIRK_BROKEN_CARD_DETECTION below}
  SDHCI_QUIRK_WAIT_SEND_CMD	          = (1 shl 6);
  SDHCI_QUIRK_NO_SIMULT_VDD_AND_POWER  = (1 shl 7); {See: SDHCI_QUIRK_NO_SIMULT_VDD_AND_POWER below}
  SDHCI_QUIRK_USE_WIDE8		          = (1 shl 8);
  SDHCI_QUIRK_MISSING_CAPS             = (1 shl 9); {See: SDHCI_QUIRK_MISSING_CAPS below}*)

  {From Linux /include/linux/mmc/sdhci.h}
  SDHCI_QUIRK_CLOCK_BEFORE_RESET			= (1 shl 0); {Controller doesn't honor resets unless we touch the clock register}
  SDHCI_QUIRK_FORCE_DMA				    = (1 shl 1); {Controller has bad caps bits, but really supports DMA}
  SDHCI_QUIRK_NO_CARD_NO_RESET			= (1 shl 2); {Controller doesn't like to be reset when there is no card inserted.}
  SDHCI_QUIRK_SINGLE_POWER_WRITE			= (1 shl 3); {Controller doesn't like clearing the power reg before a change}
  SDHCI_QUIRK_RESET_CMD_DATA_ON_IOS		= (1 shl 4); {Controller has flaky internal state so reset it on each ios change}
  SDHCI_QUIRK_BROKEN_DMA				    = (1 shl 5); {Controller has an unusable DMA engine}
  SDHCI_QUIRK_BROKEN_ADMA				= (1 shl 6); {Controller has an unusable ADMA engine}
  SDHCI_QUIRK_32BIT_DMA_ADDR			    = (1 shl 7); {Controller can only DMA from 32-bit aligned addresses}
  SDHCI_QUIRK_32BIT_DMA_SIZE			    = (1 shl 8); {Controller can only DMA chunk sizes that are a multiple of 32 bits}
  SDHCI_QUIRK_32BIT_ADMA_SIZE			= (1 shl 9); {Controller can only ADMA chunks that are a multiple of 32 bits}
  SDHCI_QUIRK_RESET_AFTER_REQUEST		= (1 shl 10); {Controller needs to be reset after each request to stay stable}
  SDHCI_QUIRK_NO_SIMULT_VDD_AND_POWER	= (1 shl 11); {Controller needs voltage and power writes to happen separately}
  SDHCI_QUIRK_BROKEN_TIMEOUT_VAL			= (1 shl 12); {Controller provides an incorrect timeout value for transfers}
  SDHCI_QUIRK_BROKEN_SMALL_PIO			= (1 shl 13); {Controller has an issue with buffer bits for small transfers}
  SDHCI_QUIRK_NO_BUSY_IRQ				= (1 shl 14); {Controller does not provide transfer-complete interrupt when not busy}
  SDHCI_QUIRK_BROKEN_CARD_DETECTION		= (1 shl 15); {Controller has unreliable card detection}
  SDHCI_QUIRK_INVERTED_WRITE_PROTECT		= (1 shl 16); {Controller reports inverted write-protect state}
  SDHCI_QUIRK_PIO_NEEDS_DELAY			= (1 shl 18); {Controller does not like fast PIO transfers}
  SDHCI_QUIRK_FORCE_BLK_SZ_2048			= (1 shl 20); {Controller has to be forced to use block size of 2048 bytes}
  SDHCI_QUIRK_NO_MULTIBLOCK			    = (1 shl 21); {Controller cannot do multi-block transfers}
  SDHCI_QUIRK_FORCE_1_BIT_DATA			= (1 shl 22); {Controller can only handle 1-bit data transfers}
  SDHCI_QUIRK_DELAY_AFTER_POWER			= (1 shl 23); {Controller needs 10ms delay between applying power and clock}
  SDHCI_QUIRK_DATA_TIMEOUT_USES_SDCLK	= (1 shl 24); {Controller uses SDCLK instead of TMCLK for data timeouts}
  SDHCI_QUIRK_CAP_CLOCK_BASE_BROKEN		= (1 shl 25); {Controller reports wrong base clock capability}
  SDHCI_QUIRK_NO_ENDATTR_IN_NOPDESC		= (1 shl 26); {Controller cannot support End Attribute in NOP ADMA descriptor}
  SDHCI_QUIRK_MISSING_CAPS			    = (1 shl 27); {Controller is missing device caps. Use caps provided by host}
  SDHCI_QUIRK_MULTIBLOCK_READ_ACMD12		= (1 shl 28); {Controller uses Auto CMD12 command to stop the transfer}
  SDHCI_QUIRK_NO_HISPD_BIT			    = (1 shl 29); {Controller doesn't have HISPD bit field in HI-SPEED SD card}
  SDHCI_QUIRK_BROKEN_ADMA_ZEROLEN_DESC	= (1 shl 30); {Controller treats ADMA descriptors with length 0000h incorrectly}
  SDHCI_QUIRK_UNSTABLE_RO_DETECT			= (1 shl 31); {The read-only detection via SDHCI_PRESENT_STATE register is unstable}

  {SDHCI More Quirks/Bugs}
  {From Linux /include/linux/mmc/sdhci.h}
  SDHCI_QUIRK2_HOST_OFF_CARD_ON			= (1 shl 0);
  SDHCI_QUIRK2_HOST_NO_CMD23			    = (1 shl 1);
  SDHCI_QUIRK2_NO_1_8_V				    = (1 shl 2); {The system physically doesn't support 1.8v, even if the host does}
  SDHCI_QUIRK2_PRESET_VALUE_BROKEN		= (1 shl 3);
  SDHCI_QUIRK2_CARD_ON_NEEDS_BUS_ON		= (1 shl 4);
  SDHCI_QUIRK2_BROKEN_HOST_CONTROL		= (1 shl 5); {Controller has a non-standard host control register}
  SDHCI_QUIRK2_BROKEN_HS200			    = (1 shl 6); {Controller does not support HS200}
  SDHCI_QUIRK2_BROKEN_DDR50			    = (1 shl 7); {Controller does not support DDR50}
  SDHCI_QUIRK2_STOP_WITH_TC			    = (1 shl 8); {Stop command(CMD12) can set Transfer Complete when not using MMC_RSP_BUSY}

  {Additions from U-Boot}
  SDHCI_QUIRK2_REG32_RW                  = (1 shl 28); {Controller requires all register reads and writes as 32bit} //To Do //Not Required ?
  SDHCI_QUIRK2_BROKEN_R1B                = (1 shl 29); {Response type R1B is broken}                                //To Do //Not Required ?
  SDHCI_QUIRK2_WAIT_SEND_CMD             = (1 shl 30); {Controller requires a delay between each command write}     //To Do //Not Required ?
  SDHCI_QUIRK2_USE_WIDE8                 = (1 shl 31); {????????}

  {SDHCI Host SDMA buffer boundary (Valid values from 4K to 512K in powers of 2)}
  SDHCI_DEFAULT_BOUNDARY_SIZE  = (512 * 1024);
  SDHCI_DEFAULT_BOUNDARY_ARG	  = (7);

  {SDHCI Timeout Value}
  SDHCI_TIMEOUT_VALUE  = $0E;

  {SDHCI/SD Status Codes}
  SDHCI_STATUS_SUCCESS                   = 0;  {Function successful}
  SDHCI_STATUS_TIMEOUT                   = 1;  {The operation timed out}
  SDHCI_STATUS_NO_MEDIA                  = 2;  {No media present in device}
  SDHCI_STATUS_HARDWARE_ERROR            = 3;  {Hardware error of some form occurred}
  SDHCI_STATUS_INVALID_DATA              = 4;  {Invalid data was received}
  SDHCI_STATUS_INVALID_PARAMETER         = 5;  {An invalid parameter was passed to the function}
  SDHCI_STATUS_INVALID_SEQUENCE          = 6;  {Invalid sequence encountered}
  SDHCI_STATUS_OUT_OF_MEMORY             = 7;  {No memory available for operation}
  SDHCI_STATUS_UNSUPPORTED_REQUEST       = 8;  {The request is unsupported}
  SDHCI_STATUS_NOT_PROCESSED             = 9;  {The SDHCI transfer has not yet been processed}

  {Application commands}
  SD_CMD_APP_SET_BUS_WIDTH	  = 6;
  SD_CMD_APP_SD_STATUS         = 13;
  SD_CMD_APP_SEND_NUM_WR_BLKS  = 22;
  SD_CMD_APP_SEND_OP_COND	  = 41;
  SD_CMD_APP_SEND_SCR		  = 51;

  {SDIO Commands (From: /include/linux/mmc/sdio.h)}
  SDIO_CMD_SEND_OP_COND       =   5;
  SDIO_CMD_RW_DIRECT          =  52;
  SDIO_CMD_RW_EXTENDED        =  53;

  {SDIO Response Values (From: /include/linux/mmc/sdio.h)}
  {R4}
  SDIO_RSP_R4_18V_PRESENT    = (1 shl 24);
  SDIO_RSP_R4_MEMORY_PRESENT = (1 shl 27);

  {R5}
  SDIO_RSP_R5_COM_CRC_ERROR	    = (1 shl 15);
  SDIO_RSP_R5_ILLEGAL_COMMAND	= (1 shl 14);
  SDIO_RSP_R5_ERROR		        = (1 shl 11);
  SDIO_RSP_R5_FUNCTION_NUMBER	= (1 shl 9);
  SDIO_RSP_R5_OUT_OF_RANGE		= (1 shl 8);


  {SDIO Commands}
  {Class 0}
  SDIO_CMD_SEND_RELATIVE_ADDR	  = 3;
  SDIO_CMD_SEND_IF_COND		  = 8;
  SDIO_CMD_SWITCH_VOLTAGE        = 11;

  {SD Send Interface Condition Values}
  SDIO_SEND_IF_COND_CHECK_PATTERN = $AA;
  SDIO_SEND_IF_COND_VOLTAGE_MASK  = $00FF8000;  {MMC_VDD_27_28, MMC_VDD_28_29, MMC_VDD_29_30, MMC_VDD_30_31, MMC_VDD_31_32, MMC_VDD_32_33, MMC_VDD_33_34, MMC_VDD_34_35, MMC_VDD_35_36}

  {SD Send Operation Condition Values}
  SDIO_SEND_OP_COND_VOLTAGE_MASK  = $00FF8000;  {MMC_VDD_27_28, MMC_VDD_28_29, MMC_VDD_29_30, MMC_VDD_30_31, MMC_VDD_31_32, MMC_VDD_32_33, MMC_VDD_33_34, MMC_VDD_34_35, MMC_VDD_35_36}


  {SDIO Card Common Control Registers (CCCR)}
  SDIO_CCCR_CCCR		= $00;
  SDIO_CCCR_SD		= $01;
  SDIO_CCCR_IOEx		= $02;
  SDIO_CCCR_IORx		= $03;
  SDIO_CCCR_IENx		= $04;	{Function/Master Interrupt Enable}
  SDIO_CCCR_INTx		= $05;	{Function Interrupt Pending}
  SDIO_CCCR_ABORT	= $06;	{function abort/card reset}
  SDIO_CCCR_IF		= $07;	{bus interface controls}
  SDIO_CCCR_CAPS		= $08;
  SDIO_CCCR_CIS		= $09;	{common CIS pointer (3 bytes)}
  {Following 4 regs are valid only if SBS is set}
  SDIO_CCCR_SUSPEND	= $0c;
  SDIO_CCCR_SELx		= $0d;
  SDIO_CCCR_EXECx	= $0e;
  SDIO_CCCR_READYx	= $0f;
  SDIO_CCCR_BLKSIZE	= $10;
  SDIO_CCCR_POWER	= $12;
  SDIO_CCCR_SPEED	= $13;
  SDIO_CCCR_UHS		= $14;
  SDIO_CCCR_DRIVE_STRENGTH = $15;

  {SDIO CCCR CCCR Register values}
  SDIO_CCCR_REV_1_00	= 0;	{CCCR/FBR Version 1.00}
  SDIO_CCCR_REV_1_10	= 1;	{CCCR/FBR Version 1.10}
  SDIO_CCCR_REV_1_20	= 2;	{CCCR/FBR Version 1.20}
  SDIO_CCCR_REV_3_00	= 3;	{CCCR/FBR Version 3.00}

  SDIO_SDIO_REV_1_00	= 0;	{SDIO Spec Version 1.00}
  SDIO_SDIO_REV_1_10	= 1;	{SDIO Spec Version 1.10}
  SDIO_SDIO_REV_1_20	= 2;	{SDIO Spec Version 1.20}
  SDIO_SDIO_REV_2_00	= 3;	{SDIO Spec Version 2.00}
  SDIO_SDIO_REV_3_00	= 4;	{SDIO Spec Version 3.00}

  {SDIO CCCR SD Register values}
  SDIO_SD_REV_1_01	= 0;	{SD Physical Spec Version 1.01}
  SDIO_SD_REV_1_10	= 1;	{SD Physical Spec Version 1.10}
  SDIO_SD_REV_2_00	= 2;	{SD Physical Spec Version 2.00}
  SDIO_SD_REV_3_00	= 3;	{SD Physical Spev Version 3.00}

  {SDIO CCCR IF Register values}
  SDIO_BUS_WIDTH_MASK	 = $03;	{data bus width setting}
  SDIO_BUS_WIDTH_1BIT	 = $00;
  SDIO_BUS_WIDTH_RESERVED = $01;
  SDIO_BUS_WIDTH_4BIT	 = $02;
  SDIO_BUS_ECSI		     = $20;	{Enable continuous SPI interrupt}
  SDIO_BUS_SCSI		     = $40;	{Support continuous SPI interrupt}

  SDIO_BUS_ASYNC_INT	     = $20;

  SDIO_BUS_CD_DISABLE     = $80;	{disable pull-up on DAT3 (pin 1)}

  {SDIO CCCR CAPS Register values}
  SDIO_CCCR_CAP_SDC	= $01;	{can do CMD52 while data transfer}
  SDIO_CCCR_CAP_SMB	= $02;	{can do multi-block xfers (CMD53)}
  SDIO_CCCR_CAP_SRW	= $04;	{supports read-wait protocol}
  SDIO_CCCR_CAP_SBS	= $08;	{supports suspend/resume}
  SDIO_CCCR_CAP_S4MI	= $10;	{interrupt during 4-bit CMD53}
  SDIO_CCCR_CAP_E4MI	= $20;	{enable ints during 4-bit CMD53}
  SDIO_CCCR_CAP_LSC	= $40;	{low speed card}
  SDIO_CCCR_CAP_4BLS	= $80;	{4 bit low speed card}

  {SDIO CCCR POWER Register values}
  SDIO_POWER_SMPC	= $01;	{Supports Master Power Control}
  SDIO_POWER_EMPC	= $02;	{Enable Master Power Control}

  {SDIO CCCR SPEED Register values}
  SDIO_SPEED_SHS		= $01;	{Supports High-Speed mode}
  SDIO_SPEED_BSS_SHIFT	= 1;
  SDIO_SPEED_BSS_MASK	= (7 shl SDIO_SPEED_BSS_SHIFT);
  SDIO_SPEED_SDR12	    = (0 shl SDIO_SPEED_BSS_SHIFT);
  SDIO_SPEED_SDR25	    = (1 shl SDIO_SPEED_BSS_SHIFT);
  SDIO_SPEED_SDR50	    = (2 shl SDIO_SPEED_BSS_SHIFT);
  SDIO_SPEED_SDR104	    = (3 shl SDIO_SPEED_BSS_SHIFT);
  SDIO_SPEED_DDR50	    = (4 shl SDIO_SPEED_BSS_SHIFT);
  SDIO_SPEED_EHS		= SDIO_SPEED_SDR25;	{Enable High-Speed}

  {SDIO CCCR UHS Register values}
  SDIO_UHS_SDR50	= $01;
  SDIO_UHS_SDR104	= $02;
  SDIO_UHS_DDR50	= $04;

  {SDIO CCCR DRIVE STRENGTH Register values}
  SDIO_SDTx_MASK		= $07;
  SDIO_DRIVE_SDTA	    = (1 shl 0);
  SDIO_DRIVE_SDTC	    = (1 shl 1);
  SDIO_DRIVE_SDTD	    = (1 shl 2);
  SDIO_DRIVE_DTSx_MASK	= $03;
  SDIO_DRIVE_DTSx_SHIFT	= 4;
  SDIO_DTSx_SET_TYPE_B	= (0 shl SDIO_DRIVE_DTSx_SHIFT);
  SDIO_DTSx_SET_TYPE_A	= (1 shl SDIO_DRIVE_DTSx_SHIFT);
  SDIO_DTSx_SET_TYPE_C	= (2 shl SDIO_DRIVE_DTSx_SHIFT);
  SDIO_DTSx_SET_TYPE_D	= (3 shl SDIO_DRIVE_DTSx_SHIFT);

  {SDIO Function Basic Registers (FBR)}
  //SDIO_FBR_BASE(f)	((f) * $100) {base of function f's FBRs}
  SDIO_FBR_STD_IF		= $00;
  SDIO_FBR_STD_IF_EXT	= $01;
  SDIO_FBR_POWER		    = $02;
  SDIO_FBR_CIS		    = $09;	{CIS pointer (3 bytes)}
  SDIO_FBR_CSA		    = $0C;	{CSA pointer (3 bytes)}
  SDIO_FBR_CSA_DATA	    = $0F;
  SDIO_FBR_BLKSIZE	    = $10;	{block size (2 bytes)}

  {SDIO FBR IF Register values}
  SDIO_FBR_SUPPORTS_CSA	= $40;	{supports Code Storage Area}
  SDIO_FBR_ENABLE_CSA	= $80;	{enable Code Storage Area}

  {SDIO FBR POWER Register values}
  SDIO_FBR_POWER_SPS	= $01;	{Supports Power Selection}
  SDIO_FBR_POWER_EPS	= $02;	{Enable (low) Power Selection}


  {SDIO Commands}
  {Class 1}
  SDIO_CMD_GO_IDLE_STATE	  = 0;
  SDIO_CMD_ALL_SEND_CID		  = 2;
  SDIO_CMD_SET_RELATIVE_ADDR	  = 3;
  SDIO_CMD_SET_DSR		  = 4;
  SDIO_CMD_SLEEP_AWAKE		  = 5;
  SDIO_CMD_SWITCH		  = 6;
  SDIO_CMD_SELECT_CARD		  = 7;
  SDIO_CMD_SEND_EXT_CSD		  = 8;
  SDIO_CMD_SEND_CSD		  = 9;
  SDIO_CMD_SEND_CID		  = 10;
  SDIO_CMD_READ_DAT_UNTIL_STOP    = 11;
  SDIO_CMD_STOP_TRANSMISSION	  = 12;
  SDIO_CMD_SEND_STATUS		  = 13;
  SDIO_CMD_BUS_TEST_R             = 14;
  SDIO_CMD_GO_INACTIVE_STATE      = 15;
  SDIO_CMD_BUS_TEST_W             = 19;
  SDIO_CMD_SPI_READ_OCR		  = 58;
  SDIO_CMD_SPI_CRC_ON_OFF	  = 59;

  {Class 2}
  SDIO_CMD_SET_BLOCKLEN		  = 16;
  SDIO_CMD_READ_SINGLE_BLOCK	  = 17;
  SDIO_CMD_READ_MULTIPLE_BLOCK  = 18;
  SDIO_CMD_SEND_TUNING_BLOCK    = 19;
  SDIO_CMD_SEND_TUNING_BLOCK_HS200 = 21;

  {Class 3}
  SDIO_CMD_WRITE_DAT_UNTIL_STOP = 20;

  {Class 4}
  SDIO_CMD_SET_BLOCK_COUNT      = 23;
  SDIO_CMD_WRITE_SINGLE_BLOCK   =	24;
  SDIO_CMD_WRITE_MULTIPLE_BLOCK =	25;
  SDIO_CMD_PROGRAM_CID          = 26;
  SDIO_CMD_PROGRAM_CSD          = 27;

  {Class 6}
  SDIO_CMD_SET_WRITE_PROT       = 28;
  SDIO_CMD_CLR_WRITE_PROT       = 29;
  SDIO_CMD_SEND_WRITE_PROT      = 30;

  {Class 5}
  SDIO_CMD_ERASE_GROUP_START	  = 35;
  SDIO_CMD_ERASE_GROUP_END	  = 36;
  SDIO_CMD_ERASE			      = 38;

  {Class 9}
  SDIO_CMD_FAST_IO              = 39;
  SDIO_CMD_GO_IRQ_STATE         = 40;

  {Class 7}
  SDIO_CMD_LOCK_UNLOCK          = 42;

  {Class 8}
  SDIO_CMD_APP_CMD			  = 55;
  SDIO_CMD_GEN_CMD              = 56;
  SDIO_CMD_RES_MAN			  = 62;

  SDIO_CMD62_ARG1			= $EFAC62EC;
  SDIO_CMD62_ARG2			= $00CBAEA7;

  // core control registers
  Ioctrl = $408;
  Resetctrl= $800;

  // socram regs
  Coreinfo = $00;
  Bankidx = $10;
  Bankinfo = $40;
  Bankpda = $44;

  // armcr4 regs
  Cr4Cap	= $04;
  Cr4Bankidx	= $40;
  Cr4Bankinfo	= $44;
  Cr4Cpuhalt	= $20;


  ARMcm3 = $82A;
  ARM7tdmi = $825;
  ARMcr4 = $83E;


  ATCM_RAM_BASE_ADDRESS = 8;

  // CCCR interrupt enable bits
  INTR_CTL_MASTER_EN  = 1;    // master interrupt enable bit
  INTR_CTL_FUNC1_EN = 2;      // function 1 interrupt enable bit
  INTR_CTL_FUNC2_EN = 4;      // function 2 interrupt enable bit

  // CCCR IO Enable bits
  SDIO_FUNC_ENABLE_1 = 2;
  SDIO_FUNC_ENABLE_2 = 4;

  WIFI_DATA_READ		= 1;
  WIFI_DATA_WRITE		= 2;

  WIFI_BAK_BLK_BYTES = 64;   // backplane block size
  WIFI_RAD_BLK_BYTES = 512;  // radio block size

  BUS_BAK_BLKSIZE_REG = $110;   // register for backplane block size (2 bytes)
  BUS_RAD_BLKSIZE_REG = $210;   // register for radio block size (2 bytes)
  BAK_WIN_ADDR_REG = $1000a;    // register for backplane window address


  Sbwsize = $8000;
  Sb32bit = $8000;


  BAK_BASE_ADDR = $18000000;   // chipcommon base address

  BAK_CHIP_CLOCK_CSR_REG = $1000e;
  ForceALP               = $01;	// active low-power clock */
  ForceHT                = $02;	// high throughput clock */
  ForceILP               = $04;	// idle low-power clock */
  ReqALP                 = $08;
  ReqHT	                 = $10;
  Nohwreq                = $20;
  ALPavail               = $40;
  HTavail                = $80;

  BAK_WAKEUP_REG = $1001e;

(*
  #define BUS_INTEN_REG           0x004   // SDIOD_CCCR_INTEN
  #define BUS_INTPEND_REG         0x005   // SDIOD_CCCR_INTPEND
  #define BUS_BI_CTRL_REG         0x007   // SDIOD_CCCR_BICTRL        Bus interface control
  #define BUS_SPEED_CTRL_REG      0x013   // SDIOD_CCCR_SPEED_CONTROL Bus speed control
  #define BUS_BRCM_CARDCAP        0x0f0   // SDIOD_CCCR_BRCM_CARDCAP
  #define BUS_BAK_BLKSIZE_REG     0x110   // SDIOD_CCCR_F1BLKSIZE_0   Backplane blocksize
  #define BUS_RAD_BLKSIZE_REG     0x210   // SDIOD_CCCR_F2BLKSIZE_0   WiFi radio blocksize*)


  // Backplane window
  SB_32BIT_WIN = $8000;


  {WIFI Bus Widths}
  WIFI_BUS_WIDTH_1	= 0;
  WIFI_BUS_WIDTH_4      = 2;

  WIFI_RSP_R1_APP_CMD			    = (1 shl 5);


  WIFI_NAME_PREFIX = 'WIFI';    {Name prefix for WIFI Devices}

  OPERATION_IO_RW_DIRECT = 6;

  {WIFI/SD Status Codes}
  WIFI_STATUS_SUCCESS                   = 0;  {Function successful}
  WIFI_STATUS_TIMEOUT                   = 1;  {The operation timed out}
  WIFI_STATUS_NO_MEDIA                  = 2;  {No media present in device}
  WIFI_STATUS_HARDWARE_ERROR            = 3;  {Hardware error of some form occurred}
  WIFI_STATUS_INVALID_DATA              = 4;  {Invalid data was received}
  WIFI_STATUS_INVALID_PARAMETER         = 5;  {An invalid parameter was passed to the function}
  WIFI_STATUS_INVALID_SEQUENCE          = 6;  {Invalid sequence encountered}
  WIFI_STATUS_OUT_OF_MEMORY             = 7;  {No memory available for operation}
  WIFI_STATUS_UNSUPPORTED_REQUEST       = 8;  {The request is unsupported}
  WIFI_STATUS_NOT_PROCESSED             = 9;  {The WIFI transfer has not yet been processed}



  {WIFI Device Types}
  WIFI_TYPE_NONE      = 0;
  WIFI_TYPE_SDIO      = 3; {An SDIO specification card}


  {WIFI Device Flags}
  WIFI_FLAG_NONE              = $00000000;

  {MMC Operation Condition Register (OCR) values} {See: Section 5.1 of SD Physical Layer Simplified Specification V4.10}
  WIFI_OCR_BUSY		   = $80000000; {Busy Status - 0 = Initializing / 1 = Initialization Complete}
  WIFI_OCR_HCS		   = $40000000; {Card Capacity Status - 0 = SDSC / 1 = SDHC or SDXC}
  WIFI_OCR_UHS_II        = $20000000; {UHS-II Card Status - 0 = Non UHS-II Card / 1 = UHS-II Card}
  WIFI_OCR_S18A          = $01000000; {Switching to 1.8V Accepted - 0 = Continue current voltage signaling / 1 = Ready for switching signal voltage}
  WIFI_OCR_VOLTAGE_MASK  = $007FFF80;
  WIFI_OCR_ACCESS_MODE   = $60000000; //To Do //??



type
  IOCTL_CMDP = ^IOCTL_CMD;
  IOCTL_CMD = record
   // sdpcm_sw_header     (hardware extension header)
    seq,                  // rx/tx sequence number
    chan,                 // 4 MSB channel number, 4 LSB aritrary flag
    nextlen,              // length of next data frame, reserved for Tx
    hdrlen,               // data offset
    flow,                 // flow control bits, reserved for tx
    credit : byte;        // maximum sequence number allowed by firmware for Tx
    reserved : word;      // reserved
    // cdc_header
    cmd : longword;
    outlen,
    inlen : word;
    flags,
    status : longword;
    data : array[0..IOCTL_MAX_BLKLEN-1] of byte;
  end;

  IOCTL_GLOM_HDR = record
    len : word;
    reserved1,
    flags : byte;
    reserved2 : word;
    pad : word;
  end;

  IOCTL_GLOM_CMD = record
    glom_hdr : IOCTL_GLOM_HDR;
    cmd : IOCTL_CMD
  end;

  PIOCTL_MSG = ^IOCTL_MSG;
  IOCTL_MSG = record
    len : word;           // frametag?  (hardware header)
    notlen : word;        // frametag?  (hardware header)
    case byte of
      1 : (cmd : IOCTL_CMD);
      2 : (glom_cmd : IOCTL_GLOM_CMD);
  end;


  TSDIODirection = (sdioRead, sdioWrite);

  byte4 = array[1..4] of byte;

  TFirmwareEntry = record
    chipid : word;
    chipidrev : word;
    firmwarefilename : string;
    configfilename : string;
    regufilename : string;
  end;

  PSDIOData = ^TSDIOData;
   PSDIOCommand = ^TSDIOCommand;
   TSDIOCommand = record
    {Command Properties}
    Command:Word;
    Argument:LongWord;
    ResponseType:LongWord;
    Response:array[0..3] of LongWord;
    Status:LongWord;
    Data:PSDIOData;
    {Host Properties}
    DataCompleted:Boolean;
    BusyCompleted:Boolean;
    TuningCompleted:Boolean;
    CommandCompleted:Boolean;
   end;

   {SDHCI Data}
   TSDIOData = record
    {Data Properties}
    Data:Pointer;
    Flags:LongWord;
    BlockSize:LongWord;
    BlockCount:LongWord;
    {Host Properties}
    BlockOffset:LongWord;
    BlocksRemaining:LongWord;
    BytesRemaining:LongWord;
    BytesTransfered:LongWord;
   end;

{WIFI Device}
  PWIFIDevice = ^TWIFIDevice;

  TWIFIDeviceInitialize = function(WIFI:PWIFIDevice):LongWord;{$IFDEF i386} stdcall;{$ENDIF}
  TWIFIDeviceSetIOS = function(WIFI:PWIFIDevice):LongWord;{$IFDEF i386} stdcall;{$ENDIF}
  TWIFIDeviceSendCommand = function(WIFI:PWIFIDevice;Command:PSDIOCommand):LongWord;{$IFDEF i386} stdcall;{$ENDIF}


  TWIFIDevice = record
   {Device Properties}
   Device:TDevice;                                  {The Device entry for this WIFI device}
   {WIFI Properties}
   WIFIId:LongWord;                                  {Unique Id of this WIFI device in the MMC }
//   MMCState:LongWord;                               {MMC state (eg MMC_STATE_INSERTED)}
   DeviceInitialize:TWIFIDeviceInitialize;           {A Device specific DeviceInitialize method implementing a standard MMC device interface (Or nil if the default method is suitable)}
//   DeviceDeinitialize:TMMCDeviceDeinitialize;       {A Device specific DeviceDeinitialize method implementing a standard MMC device interface (Or nil if the default method is suitable)}
//   DeviceGetCardDetect:TMMCDeviceGetCardDetect;     {A Device specific DeviceGetCardDetect method implementing a standard MMC device interface (Or nil if the default method is suitable)}
//   DeviceGetWriteProtect:TMMCDeviceGetWriteProtect; {A Device specific DeviceGetWriteProtect method implementing a standard MMC device interface (Or nil if the default method is suitable)}
   DeviceSendCommand:TWIFIDeviceSendCommand;         {A Device specific DeviceSendCommand method implementing a standard MMC device interface (Or nil if the default method is suitable)}
   DeviceSetIOS:TWIFIDeviceSetIOS;                   {A Device specific DeviceSetIOS method implementing a standard MMC device interface (Or nil if the default method is suitable)}
   {Statistics Properties}
   CommandCount:LongWord;
   CommandErrors:LongWord;
   {Driver Properties}
   Lock:TMutexHandle;                               {Device lock}
   Version:LongWord;
   Clock:LongWord;
   Timing:LongWord;
   BusWidth:LongWord;
   Voltages:LongWord;
   Capabilities:LongWord;
   {Register Properties}                            {See: Table 3-2: SD Memory Card Registers of SD Physical Layer Simplified Specification Version 4.10}
   InterfaceCondition:LongWord;                     {Interface Condition Result}
   OperationCondition:LongWord;                     {Operation Condition Register (OCR)} {See: Section 5.1 of SD Physical Layer Simplified Specification Version 4.10}
   RelativeCardAddress:LongWord;                    {Relative Card Address (RCA) (Word)} {See: Section 5.4 of SD Physical Layer Simplified Specification Version 4.10}
   CardSpecific:array[0..3] of LongWord;            {Card Specific Data (CSD)}           {See: Section 5.3 of SD Physical Layer Simplified Specification Version 4.10}
   CardIdentification:array[0..3] of LongWord;      {Card Identification Data (CID)}     {See: Section 5.2 of SD Physical Layer Simplified Specification Version 4.10}
   CardStatus:LongWord;                             {Card Status Register (CSR)}         {See: Section 4.10.1 of SD Physical Layer Simplified Specification Version 4.10}
   DriverStage:LongWord;                            {Driver Stage Register (DSR) (Word)} {See: Section 5.5 of SD Physical Layer Simplified Specification Version 4.10}
   SDStatus:array[0..15] of LongWord;               {SD Status Register (SSR)}           {See: Section 4.10.2 of SD Physical Layer Simplified Specification Version 4.10}
   SDSwitch:array[0..15] of LongWord;               {SD Switch Status}                   {See: Section 4.3.10 of SD Physical Layer Simplified Specification Version 4.10}
   SDConfiguration:array[0..1] of LongWord;         {SD Configuration Register (SCR)}    {See: Section 5.6 of SD Physical Layer Simplified Specification Version 4.10}

   // wifi chip data - some may not be needed.

   chipid : word;
   chipidrev : word;
   armcore : longword;
   chipcommon : longword;
   armctl : longword;
   armregs : longword;
   d11ctl : longword;
   socramregs : longword;
   socramctl : longword;
   socramrev : longword;
   sdregs : longword;
   sdiorev : longword;
   socramsize : longword;
   rambase : longword;
   dllctl : longword;
   resetvec : longword;

   {Configuration Properties}
//   CardSpecificData:TMMCCardSpecificData;
//   CardIdentificationData:TMMCCardIdentificationData;
//   SDStatusData:TSDStatusData;
//   SDSwitchData:TSDSwitchData;
//   SDConfigurationData:TSDConfigurationData;
   {Storage Properties}
//   Storage:PStorageDevice;                          {The Storage entry for this MMC (Where Applicable)}
   {Internal Properties}
   Prev:PWIFIDevice;                                 {Previous entry in WIFI table}
   Next:PWIFIDevice;                                 {Next entry in WIFI table}
  end;

  whd_event_eth_hdr = record
      subtype : word;                 // Vendor specific..32769
      length : word;
      version : byte;                 // Version is 0
      oui : array[0..2] of byte;      //  OUI
      usr_subtype : word;             // user specific Data
  end;

  whd_event_ether_header = record
      destination_address : array[0..5] of byte;
      source_address : array[0..5] of byte;
      ethertype : word;
  end;

  whd_event_msg = record
      version : word;
      flags : word;                                    // see flags below
      event_type : longword;                           // Message (see below)
      status : longword;                               // Status code (see below)
      reason : longword;                               // Reason code (if applicable)
      auth_type : longword;                            // WLC_E_AUTH
      datalen : longword;                              // data buf
      addr : array[0..5] of byte;                      // Station address (if applicable)
      ifname : array[0..WHD_MSG_IFNAME_MAX-1] of char; // name of the packet incoming interface
      ifidx : byte;                                    // destination OS i/f index
      bsscfgidx : byte;                                // source bsscfg index
  end;

  // used by driver msgs
  pwhd_event = ^whd_event;
  whd_event = record
      eth : whd_event_ether_header;
      eth_evt_hdr : whd_event_eth_hdr ;
      whd_event : whd_event_msg;
      // data portion follows */
  end;

  // The code uses the ordinal value of this type to match against the event value
  // received from the firmware, so so order is important. Therefore do not change it.

//  WLC_E_NONE,
  TWIFIEvent = (
    WLC_E_SET_SSID,                    // indicates status of set SSID ,
    WLC_E_JOIN,                        // differentiates join IBSS from found (WLC_E_START) IBSS
    WLC_E_START,                       // STA founded an IBSS or AP started a BSS
    WLC_E_AUTH,                        // 802.11 AUTH request
    WLC_E_AUTH_IND,                    // 802.11 AUTH indication
    WLC_E_DEAUTH,                      // 802.11 DEAUTH request
    WLC_E_DEAUTH_IND,                  // 802.11 DEAUTH indication
    WLC_E_ASSOC,                       // 802.11 ASSOC request
    WLC_E_ASSOC_IND,                   // 802.11 ASSOC indication
    WLC_E_REASSOC,                     // 802.11 REASSOC request
    WLC_E_REASSOC_IND,                 // 802.11 REASSOC indication
    WLC_E_DISASSOC,                    // 802.11 DISASSOC request
    WLC_E_DISASSOC_IND,                // 802.11 DISASSOC indication
    WLC_E_QUIET_START,                 // 802.11h Quiet period started
    WLC_E_QUIET_END,                   // 802.11h Quiet period ended
    WLC_E_BEACON_RX,                   // BEACONS received/lost indication
    WLC_E_LINK,                        // generic link indication
    WLC_E_MIC_ERROR,                   // TKIP MIC error occurred
    WLC_E_NDIS_LINK,                   // NDIS style link indication
    WLC_E_ROAM,                        // roam attempt occurred: indicate status & reason
    WLC_E_TXFAIL,                      // change in dot11FailedCount (txfail)
    WLC_E_PMKID_CACHE,                 // WPA2 pmkid cache indication
    WLC_E_RETROGRADE_TSF,              // current AP's TSF value went backward
    WLC_E_PRUNE,                       // AP was pruned from join list for reason
    WLC_E_AUTOAUTH,                    // report AutoAuth table entry match for join attempt
    WLC_E_EAPOL_MSG,                   // Event encapsulating an EAPOL message
    WLC_E_SCAN_COMPLETE,               // Scan results are ready or scan was aborted
    WLC_E_ADDTS_IND,                   // indicate to host addts fail/success
    WLC_E_DELTS_IND,                   // indicate to host delts fail/success
    WLC_E_BCNSENT_IND,                 // indicate to host of beacon transmit
    WLC_E_BCNRX_MSG,                   // Send the received beacon up to the host
    WLC_E_BCNLOST_MSG,                 // indicate to host loss of beacon
    WLC_E_ROAM_PREP,                   // before attempting to roam
    WLC_E_PFN_NET_FOUND,               // PFN network found event
    WLC_E_PFN_NET_LOST,                // PFN network lost event
    WLC_E_RESET_COMPLETE = 35,
    WLC_E_JOIN_START = 36,
    WLC_E_ROAM_START = 37,
    WLC_E_ASSOC_START = 38,
    WLC_E_IBSS_ASSOC = 39,
    WLC_E_RADIO = 40,
    WLC_E_PSM_WATCHDOG,                // PSM microcode watchdog fired
    WLC_E_CCX_ASSOC_START,             // CCX association start
    WLC_E_CCX_ASSOC_ABORT,             // CCX association abort
    WLC_E_PROBREQ_MSG,                 // probe request received
    WLC_E_SCAN_CONFIRM_IND = 45,
    WLC_E_PSK_SUP,                     // WPA Handshake
    WLC_E_COUNTRY_CODE_CHANGED = 47,
    WLC_E_EXCEEDED_MEDIUM_TIME,        // WMMAC excedded medium time
    WLC_E_ICV_ERROR,                   // WEP ICV error occurred
    WLC_E_UNICAST_DECODE_ERROR,        // Unsupported unicast encrypted frame
    WLC_E_MULTICAST_DECODE_ERROR,      // Unsupported multicast encrypted frame
    WLC_E_TRACE = 52,
    WLC_E_BTA_HCI_EVENT,               // BT-AMP HCI event
    WLC_E_IF,                          // I/F change (for wlan host notification)
    WLC_E_P2P_DISC_LISTEN_COMPLETE,    // P2P Discovery listen state expires
    WLC_E_RSSI,                        // indicate RSSI change based on configured levels
    WLC_E_PFN_BEST_BATCHING,           // PFN best network batching event
    WLC_E_EXTLOG_MSG,
    WLC_E_ACTION_FRAME,                // Action frame reception
    WLC_E_ACTION_FRAME_COMPLETE,       // Action frame Tx complete
    WLC_E_PRE_ASSOC_IND,               // assoc request received
    WLC_E_PRE_REASSOC_IND,             // re-assoc request received
    WLC_E_CHANNEL_ADOPTED,             // channel adopted (xxx: obsoleted)
    WLC_E_AP_STARTED,                  // AP started
    WLC_E_DFS_AP_STOP,                 // AP stopped due to DFS
    WLC_E_DFS_AP_RESUME,               // AP resumed due to DFS
    WLC_E_WAI_STA_EVENT,               // WAI stations event
    WLC_E_WAI_MSG,                     // event encapsulating an WAI message
    WLC_E_ESCAN_RESULT,                // escan result event
    WLC_E_ACTION_FRAME_OFF_CHAN_COMPLETE, // NOTE - This used to be WLC_E_WAKE_EVENT
    WLC_E_PROBRESP_MSG,                // probe response received
    WLC_E_P2P_PROBREQ_MSG,             // P2P Probe request received
    WLC_E_DCS_REQUEST = 73,
    WLC_E_FIFO_CREDIT_MAP,             // credits for D11 FIFOs. [AC0,AC1,AC2,AC3,BC_MC,ATIM]
    WLC_E_ACTION_FRAME_RX,             // Received action frame event WITH wl_event_rx_frame_data_t header
    WLC_E_WAKE_EVENT,                  // Wake Event timer fired, used for wake WLAN test mode
    WLC_E_RM_COMPLETE,                 // Radio measurement complete
    WLC_E_HTSFSYNC,                    // Synchronize TSF with the host
    WLC_E_OVERLAY_REQ,                 // request an overlay IOCTL/iovar from the host
    WLC_E_CSA_COMPLETE_IND = 80,
    WLC_E_EXCESS_PM_WAKE_EVENT,        // excess PM Wake Event to inform host
    WLC_E_PFN_SCAN_NONE,               // no PFN networks around
    WLC_E_PFN_SCAN_ALLGONE,            // last found PFN network gets lost
    WLC_E_GTK_PLUMBED,
    WLC_E_ASSOC_IND_NDIS,              // 802.11 ASSOC indication for NDIS only
    WLC_E_REASSOC_IND_NDIS,            // 802.11 REASSOC indication for NDIS only
    WLC_E_ASSOC_REQ_IE,
    WLC_E_ASSOC_RESP_IE,
    WLC_E_ASSOC_RECREATED,             // association recreated on resume
    WLC_E_ACTION_FRAME_RX_NDIS,        // rx action frame event for NDIS only
    WLC_E_AUTH_REQ,                    // authentication request received
    WLC_E_TDLS_PEER_EVENT,             // discovered peer, connected/disconnected peer
    //WLC_E_MESH_DHCP_SUCCESS,         // DHCP handshake successful for a mesh interface. Note commented out as duplicate ID with previous in cypress code
    WLC_E_SPEEDY_RECREATE_FAIL,        // fast assoc recreation failed
    WLC_E_NATIVE,                      // port-specific event and payload (e.g. NDIS)
    WLC_E_PKTDELAY_IND,                // event for tx pkt delay suddently jump
    WLC_E_AWDL_AW,                     // AWDL AW period starts
    WLC_E_AWDL_ROLE,                   // AWDL Master/Slave/NE master role event
    WLC_E_AWDL_EVENT,                  // Generic AWDL event
    WLC_E_NIC_AF_TXS,                  // NIC AF txstatus
    WLC_E_NAN,                         // NAN event
    WLC_E_BEACON_FRAME_RX = 101,
    WLC_E_SERVICE_FOUND,               // desired service found
    WLC_E_GAS_FRAGMENT_RX,             // GAS fragment received
    WLC_E_GAS_COMPLETE,                // GAS sessions all complete
    WLC_E_P2PO_ADD_DEVICE,             // New device found by p2p offload
    WLC_E_P2PO_DEL_DEVICE,             // device has been removed by p2p offload
    WLC_E_WNM_STA_SLEEP,               // WNM event to notify STA enter sleep mode
    WLC_E_TXFAIL_THRESH,               // Indication of MAC tx failures (exhaustion of 802.11 retries) exceeding threshold(s)
    WLC_E_PROXD,                       // Proximity Detection event
    WLC_E_IBSS_COALESCE,               // IBSS Coalescing
    //WLC_E_MESH_PAIRED,               // Mesh peer found and paired     Note commented out as duplicate ID with previous in cypress code
    WLC_E_AWDL_RX_PRB_RESP,            // AWDL RX Probe response
    WLC_E_AWDL_RX_ACT_FRAME,           // AWDL RX Action Frames
    WLC_E_AWDL_WOWL_NULLPKT,           // AWDL Wowl nulls
    WLC_E_AWDL_PHYCAL_STATUS,          // AWDL Phycal status
    WLC_E_AWDL_OOB_AF_STATUS,          // AWDL OOB AF status
    WLC_E_AWDL_SCAN_STATUS,            // Interleaved Scan status
    WLC_E_AWDL_AW_START,               // AWDL AW Start
    WLC_E_AWDL_AW_END,                 // AWDL AW End
    WLC_E_AWDL_AW_EXT,                 // AWDL AW Extensions
    WLC_E_AWDL_PEER_CACHE_CONTROL0,
    WLC_E_CSA_START_IND,
    WLC_E_CSA_DONE_IND,
    WLC_E_CSA_FAILURE_IND,
    WLC_E_CCA_CHAN_QUAL,                 // CCA based channel quality report
    WLC_E_BSSID,                         // to report change in BSSID while roaming
    WLC_E_TX_STAT_ERROR,                 // tx error indication
    WLC_E_BCMC_CREDIT_SUPPORT,           // credit check for BCMC supported
    WLC_E_PSTA_PRIMARY_INTF_IND,         // psta primary interface indication
    WLC_E_129,
    WLC_E_BT_WIFI_HANDOVER_REQ,          // Handover Request Initiated
    WLC_E_SPW_TXINHIBIT,                 // Southpaw TxInhibit notification
    WLC_E_FBT_AUTH_REQ_IND,              // FBT Authentication Request Indication
    WLC_E_RSSI_LQM,                      // Enhancement addition for WLC_E_RSSI
    WLC_E_PFN_GSCAN_FULL_RESULT,         // Full probe/beacon (IEs etc) results
    WLC_E_PFN_SWC,                       // Significant change in rssi of bssids being tracked
    WLC_E_AUTHORIZED,                    // a STA been authroized for traffic
    WLC_E_PROBREQ_MSG_RX,                // probe req with wl_event_rx_frame_data_t header
    WLC_E_PFN_SCAN_COMPLETE,             // PFN completed scan of network list
    WLC_E_RMC_EVENT,                     // RMC Event
    WLC_E_DPSTA_INTF_IND,                // DPSTA interface indication
    WLC_E_RRM,                           // RRM Event
    WLC_E_142,
    WLC_E_143,
    WLC_E_144,
    WLC_E_145,
    WLC_E_ULP,                           // ULP entry event
    WLC_E_147,
    WLC_E_148,
    WLC_E_149,
    WLC_E_150,
    WLC_E_TKO,                           // TCP Keep Alive Offload Event
    WLC_E_LASTONE);

  TWIFIEventSet = set of TWIFIEvent;

  PWIFIRequestItem = ^TWIFIRequestItem;

  TWirelessEventCallback = procedure(Event : TWIFIEvent; EventRecordP : pwhd_event; RequestItemP : PWIFIRequestItem);

  TWIFIRequestItem = record
    RequestID : Word;
    RegisteredEvents : TWIFIEventSet;
    MsgP : PIOCTL_MSG;
    Signal : TSemaphoreHandle;
    Callback : TWirelessEventCallback;
    NextP : PWIFIRequestItem;
  end;

  TWIFIWorkerThread = class(TThread)
  private
    FRequestQueueP : PWIFIRequestItem;
    FLastRequestQueueP : PWIFIRequestItem;
    FQueueProtect : TCriticalSectionHandle;
  public
    FWIFI : PWIFIDevice;
    constructor Create(CreateSuspended : Boolean; AWIFI : PWIFIDevice);
    destructor Destroy; override;
    function AddRequest(ARequestID : word; InterestedEvents : TWIFIEventSet; Callback : TWirelessEventCallback) : PWIFIRequestItem;
    procedure DoneWithRequest(ARequestItemP : PWIFIRequestItem);
    function FindRequest(ARequestId : word) : PWIFIRequestItem;
    function FindRequestByEvent(AEvent : longword) : PWIFIRequestItem;
    procedure dumpqueue;
    procedure Execute; override;
  end;


function WIFIDeviceCreate:PWIFIDevice;
function WIFIDeviceCreateEx(Size:LongWord):PWIFIDevice;
function WIFIDeviceDestroy(WIFI:PWIFIDevice):LongWord;
function WIFIDeviceCheck(WIFI:PWIFIDevice):PWIFIDevice;
function WIFIDeviceInitialize(WIFI:PWIFIDevice):LongWord;

function WIFIDeviceRegister(WIFI:PWIFIDevice):LongWord;
function WIFIDeviceFind(WIFIId:LongWord):PWIFIDevice;

function SDIOWIFIDeviceReset(WIFI:PWIFIDevice):LongWord;
function WIFIDeviceGoIdle(WIFI:PWIFIDevice):LongWord;
function SDWIFIDeviceSendInterfaceCondition(WIFI:PWIFIDevice):LongWord;
function SDIOWIFIDeviceSendOperationCondition(WIFI:PWIFIDevice;Probe:Boolean):LongWord;
function SDIOWIFIDeviceReadWriteDirect(WIFI:PWIFIDevice;Direction : TSDIODirection;Operation,Address:LongWord;Input:Byte;Output:PByte):LongWord;
function SDIOWIFIDeviceReadWriteExtended(WIFI:PWIFIDevice; Direction : TSDIODirection;
            Operation, Address : LongWord;
            Increment : Boolean; Buffer : Pointer;
            BlockCount, BlockSize : LongWord; callerid:integer=0): LongWord;
function WIFIDeviceSendCommand(WIFI:PWIFIDevice;Command:PSDIOCommand; txdata : PSDIOData = nil):LongWord;
function WIFIDeviceSetClock(WIFI:PWIFIDevice;Clock:LongWord):LongWord;
function WIFIDeviceSetBackplaneWindow(WIFI : PWIFIDevice; addr : longword) : longword;
function WIFIDeviceCoreScan(WIFI : PWIFIDevice) : longint;
procedure WIFIDeviceRamScan(WIFI : PWIFIDevice);
function WIFIDeviceDownloadFirmware(WIFI : PWIFIDevice) : Longword;

procedure sbreset(WIFI : PWIFIDevice; regs : longword; pre : word; ioctl : word);
procedure sbdisable(WIFI : PWIFIDevice; regs : longword; pre : word; ioctl : word);



function WIFIDeviceSendApplicationCommand(WIFI:PWIFIDevice;Command:PSDIOCommand):LongWord;

procedure WIFILogError(WIFI:PWIFIDevice;const AText:String); inline;
function WIFIDeviceSetIOS(WIFI:PWIFIDevice):LongWord;

procedure WirelessScan(WIFI : PWIFIDevice);
procedure WirelessJoinNetwork(WIFI : PWIFIDevice; ssid : string; security_key : string);


var
  WIFI_LOG_ENABLED : boolean = true;

  // this will be moved to the implementation section eventually
  // just here because we currently need to create it externally
  // and that is because the SDHCI and WIFI Device are being created externally.
  WIFIWorkerThread : TWIFIWorkerThread;


implementation

const
  {WIFI logging}
  WIFI_LOG_LEVEL_DEBUG     = LOG_LEVEL_DEBUG;  {WIFI debugging messages}
  WIFI_LOG_LEVEL_INFO      = LOG_LEVEL_INFO;   {WIFI informational messages, such as a device being attached or detached}
  WIFI_LOG_LEVEL_WARN      = LOG_LEVEL_WARN;   {WIFI warning messages}
  WIFI_LOG_LEVEL_ERROR     = LOG_LEVEL_ERROR;  {WIFI error messages}
  WIFI_LOG_LEVEL_NONE      = LOG_LEVEL_NONE;   {No WIFI messages}


type

  ether_addr = record
    octet : array[0..ETHER_ADDR_LEN-1] of byte;
  end;

  wlc_ssid = record
    SSID_len : longword;
    SSID : array[0..31] of byte;
  end;

  chanrec = record
    chan : byte;
    other : byte;
  end;

  wl_scan_params = record
    ssid : wlc_ssid;
    bssid : ether_addr;
    bss_type : byte;
    scan_type : byte;
    nprobes : longword;
    active_time : longword;
    passive_time : longword;
    home_time : longword;
    channel_num : longword;
    channel_list : array[1..14] of chanrec;  // this is used in the cypress driver to allow channels to be optionally provided
                                         // it does a memory allocation and then accesses beyond the first element of the
                                         // array as needed. We need a different syntactic implementation for Pascal.
                                         // we'll start by scanning all channels to avoid it.
    ssids : array[0..SSID_MAX_LEN-1] of word;
  end;


  wl_escan_params = record
    version : longword;
    action : word;
    sync_id : word;
    params : wl_scan_params;
  end;

  wl_chanspec = integer;

  pwl_bss_info = ^wl_bss_info;
  wl_bss_info = record
      version : longword;                       // version field
      length : longword;                        // byte length of data in this record, starting at version and including IEs
      BSSID : ether_addr;                       // Unique 6-byte MAC address
      beacon_period : word;                     // Interval between two consecutive beacon frames. Units are Kusec
      capability : word;                        // Capability information
      SSID_len : byte;                          // SSID length
      SSID : array[0..31] of char;                // Array to store SSID

      // this is a sub struct in cypress driver.
          ratecount : longword;                 // Count of rates in this set
          rates : array[1..15] of byte;         // rates in 500kbps units, higher bit set if basic

      chanspec : wl_chanspec ;                   // Channel specification for basic service set
      atim_window : word;                       // Announcement traffic indication message window size. Units are Kusec
      dtim_period : byte;                       // Delivery traffic indication message period
      RSSI : integer;                           // receive signal strength (in dBm)
      phy_noise : shortint;                     // noise (in dBm)

      n_cap : byte;                             // BSS is 802.11N Capable
      nbss_cap : longword;                      // 802.11N BSS Capabilities (based on HT_CAP_*)
      ctl_ch : byte;                            // 802.11N BSS control channel number
      reserved32 : array[1..1] of longword;       // Reserved for expansion of BSS properties
      flags : byte;                             // flags
      reserved : array[1..3] of byte;           // Reserved for expansion of BSS properties
      basic_mcs : array[0..MCSSET_LEN-1] of byte; // 802.11N BSS required MCS set

      ie_offset : word;                         // offset at which IEs start, from beginning
      ie_length : longword;                     // byte length of Information Elements
      SNR : integer;                            // Average SNR(signal to noise ratio) during frame reception
      // Add new fields here
      // variable length Information Elements
  end;

  pwl_escan_result = ^wl_escan_result;
  wl_escan_result = record
    buflen : longword;
    version : longword;
    sync_id : word;
    bss_count : word;
    bss_info : array [1..1] of wl_bss_info; // used as pointer to a list. perhaps change to pwl_bss_info?
  end;


  pwhd_tlv8_header = ^whd_tlv8_header;
  whd_tlv8_header = record
    atype : byte;
    length : byte;
  end;


  pwhd_tlv8_data = ^whd_tlv8_data;
  whd_tlv8_data = record
    atype : byte;
    length : byte;
    data : array[1..1] of byte;    // used as a pointer to a list. perhaps change to pybte instead.
  end;

  prsn_ie_fixed_portion = ^rsn_ie_fixed_portion;
  rsn_ie_fixed_portion = record
    tlv_header : whd_tlv8_header; //id, length
    version : word;
    group_key_suite : longword; // See whd_80211_cipher_t for values
    pairwise_suite_count : word;
    pairwise_suite_list : array[1..1] of longword;
  end;


var
  WIFI_DEFAULT_LOG_LEVEL:LongWord = WIFI_LOG_LEVEL_DEBUG; {Minimum level for WIFI messages.  Only messages with level greater than or equal to this will be printed}
  WIFIDeviceTableLock:TCriticalSectionHandle = INVALID_HANDLE_VALUE;

  WIFIDeviceTable:PWIFIDevice;
  WIFIDeviceTableCount:LongWord;

  WIFIInitialized:Boolean;

  dodumpregisters : boolean = false;

  chipid : word;
  chipidrev : word;
  firmwarefilename : string;
  configfilename : string;
  regufilename : string;

  firmware : array[1..FIRWMARE_OPTIONS_COUNT] of TFirmwareEntry =
    (
    	( chipid : $4330; chipidrev : 3; firmwarefilename: 'fw_bcm40183b1.bin'; configfilename: 'bcmdhd.cal.40183.26MHz'; regufilename : ''),
    	( chipid : $4330; chipidrev : 4; firmwarefilename: 'fw_bcm40183b2.bin'; configfilename: 'bcmdhd.cal.40183.26MHz'; regufilename : ''),
    	( chipid : 43362; chipidrev : 0; firmwarefilename: 'fw_bcm40181a0.bin'; configfilename: 'bcmdhd.cal.40181'; regufilename : ''),
    	( chipid : 43362; chipidrev : 1; firmwarefilename: 'fw_bcm40181a2.bin'; configfilename: 'bcmdhd.cal.40181'; regufilename : ''),
    	( chipid : 43430; chipidrev : 1; firmwarefilename: 'brcmfmac43430-sdio.bin'; configfilename: 'brcmfmac43430-sdio.txt'; regufilename : ''),
    	( chipid : $4345; chipidrev : 6; firmwarefilename: 'brcmfmac43455-sdio.bin'; configfilename: 'brcmfmac43455-sdio.txt'; regufilename : 'brcmfmac43455-sdio.clm_blob'),
    	( chipid : $4345; chipidrev : 9; firmwarefilename: 'brcmfmac43456-sdio.bin'; configfilename: 'brcmfmac43456-sdio.txt'; regufilename : 'brcmfmac43456-sdio.clm_blob')
    );


  ioctl_txmsg, ioctl_rxmsg : IOCTL_MSG;
  txglom : boolean = false; // don't know what this is for yet.
  ioctl_reqid : longword = 1; // ioct request id used to match request to response.
                              // starts at 1 because 0 is reserved for an event entry.

  txseq : byte = 1; // ioctl tx sequence number.

  SDIOProtect : TSpinHandle;



procedure sbenable(WIFI : PWIFIDevice); forward;
procedure WirelessInit(WIFI : PWIFIDevice); forward;
procedure WIFILogInfo(WIFI: PWIFIDevice;const AText:String); forward;



procedure hexdump(p : pbyte; len : word);
var
  rows : integer;
  remainder : integer;
  i : integer;

  function line(bytecount : integer) : string;
  var
    s : string;
    asc : string;
    j : integer;
    b : byte;
  begin
     s := '';
     asc := '';

     s := s + inttohex(i*16, 4) + ' ';
     for j := 0 to bytecount-1 do
     begin
       b := (p+(i*16)+j)^;
       s := s + inttohex(b, 2) +' ' ;
       if (b in [28..126]) then
         asc := asc + chr(b)
       else
         asc := asc + '.';
     end;

     if (bytecount < 16) then
       for j := 15 downto bytecount do
         s := s + '   ';

     s := s + ' ' + asc;

     Result := s;
  end;

begin
  rows := len div 16;
  remainder := len mod 16;

  for i := 0 to rows-1 do
  begin
     wifiloginfo(nil, line(16));
  end;
  i+=16;
  if (remainder > 0) then
    wifiloginfo(nil, line(remainder));
end;

function NetSwapLong(v : longword) : longword; inline;
begin
  Result:= ((v and $ff) << 24) or ((v and $ff00) << 8) or ((v and $ff0000) >> 8) or ((v and $ff000000) >> 24);
end;

function NetSwapWord(v : word) : word; inline;
begin
 Result := ((v and $ff) << 8) or ((v and $ff00) >> 8);
end;

function buftostr(bufferp : pbyte; messagelen : word; nullterminated : boolean = false) : string;
var
 i : integer;
 b : byte;
begin
 try
  Result := '';
  for i := 0 to messagelen-1 do
  begin
    b := (bufferp+i)^;

    if (nullterminated) and (b = 0) then
      exit;

    if (b in [32..126]) then
      Result := Result + chr(b)
    else
      Result := Result + '[#'+inttostr(b)+']';
  end;

 except
   on e : exception do
     wifiloginfo(nil, 'exception in buftostr ' + e.message + ' i='+inttostr(i));
 end;
end;

procedure WIFILog(Level:LongWord;WIFI:PWIFIDevice;const AText:String);
var
 WorkBuffer:String;
begin
 {}
 {Check Level}
 if Level < WIFI_DEFAULT_LOG_LEVEL then Exit;

 WorkBuffer:='';
 {Check Level}
 if Level = WIFI_LOG_LEVEL_DEBUG then
  begin
   WorkBuffer:=WorkBuffer + '[DEBUG] ';
  end
 else if Level = WIFI_LOG_LEVEL_WARN then
  begin
   WorkBuffer:=WorkBuffer + '[WARN] ';
  end
 else if Level = WIFI_LOG_LEVEL_ERROR then
  begin
   WorkBuffer:=WorkBuffer + '[ERROR] ';
  end;

 {Add Prefix}
 WorkBuffer:=WorkBuffer + 'WIFI: ';

 {Check WIFI}
 if WIFI <> nil then
  begin
   WorkBuffer:=WorkBuffer + WIFI_NAME_PREFIX + IntToStr(WIFI^.WIFIId) + ': ';
  end;

 {Output Logging}
 LoggingOutputEx(LOGGING_FACILITY_DEVICES,LogLevelToLoggingSeverity(Level),'WIFIdevice',WorkBuffer + AText);
end;

procedure WIFILogError(WIFI:PWIFIDevice;const AText:String); inline;
begin
 {}
 WIFILog(WIFI_LOG_LEVEL_ERROR,WIFI,AText);
end;

{==============================================================================}

procedure WIFILogDebug(WIFI: PWIFIDevice;const AText:String); inline;
begin
 {}
 WIFILog(WIFI_LOG_LEVEL_DEBUG,WIFI,AText);
end;

procedure WIFILogInfo(WIFI: PWIFIDevice;const AText:String); inline;
begin
 {}
 WIFILog(WIFI_LOG_LEVEL_INFO,WIFI,AText);
end;

procedure dumpregisters(WIFI : PWIFIDevice);
type
  arrayptr = ^arraytype;
  arraytype = array[0..99] of longword;
  arrayptrbytes = ^arraybytes;
  arraybytes = array[0..1000] of byte;
var
  SDHCI : PSDHCIHost;
  r : arrayptr;
  rb : arrayptrbytes;
begin
   SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);

    r := arrayptr(SDHCI^.address);
    rb := arrayptrbytes(SDHCI^.address);


    wifiloginfo(nil, '32 bit block count 0x'+ inttohex(r^[0], 8));
    wifiloginfo(nil, 'blocksize and count 0x'+ inttohex(r^[1], 8));
    wifiloginfo(nil, 'arg 0x%x'+ inttohex(r^[2], 8));
    wifiloginfo(nil, 'transfermode and command 0x'+ inttohex(r^[3], 8));
    wifiloginfo(nil, 'response0 0x'+ inttohex(r^[4], 8));
    wifiloginfo(nil, 'response1 0x'+ inttohex(r^[5], 8));
    wifiloginfo(nil, 'response2 0x'+ inttohex(r^[6], 8));
    wifiloginfo(nil, 'response3 0x'+ inttohex(r^[7], 8));
    //wifiloginfo(nil, 'buffer data port 0x%x'+ inttohex(r^[8], 8));
    wifiloginfo(nil, 'present state 0x'+ inttohex(r^[9], 8));
    wifiloginfo(nil, 'host ctrl1, pwr ctrl, block gap ctrl, wakeup ctrl0x'+ inttohex(r^[10], 8));


    wifiloginfo(nil, 'host ctrl1 0x' +inttohex(rb^[SDHCI_HOST_CONTROL], 2));
    wifiloginfo(nil, 'pwr ctrl 0x' +inttohex(rb^[SDHCI_POWER_CONTROL], 2));
    wifiloginfo(nil, 'block gap ctrl 0x' +inttohex(rb^[SDHCI_BLOCK_GAP_CONTROL], 2));
    wifiloginfo(nil, 'wakeup ctrl 0x' +inttohex(rb^[SDHCI_WAKE_UP_CONTROL], 2));

    wifiloginfo(nil, 'clock ctrl, timeout ctrl, sw reset 0x'+ inttohex(r^[11], 8));

    wifiloginfo(nil, 'clock ctrl byte 1 0x' +inttohex(rb^[SDHCI_CLOCK_CONTROL], 2));
    wifiloginfo(nil, 'clock ctrl byte 2 0x' +inttohex(rb^[SDHCI_CLOCK_CONTROL+1], 2));
    wifiloginfo(nil, 'timeout ctrl 0x' +inttohex(rb^[SDHCI_TIMEOUT_CONTROL], 2));
    wifiloginfo(nil, 'sw reset 0x' +inttohex(rb^[SDHCI_SOFTWARE_RESET], 2));


    wifiloginfo(nil, 'normal interrupt status, error interrupt status 0x'+ inttohex(r^[12], 8));
    wifiloginfo(nil, 'normal interr enable, error interr enable 0x'+ inttohex(r^[13], 8));
    wifiloginfo(nil, 'auto cmd status, host ctrl 2 0x'+ inttohex(r^[14], 8));
    wifiloginfo(nil, 'capabilities part 1 0x'+ inttohex(r^[15], 8));
    wifiloginfo(nil, 'capabilities part 2 0x'+ inttohex(r^[16], 8));
end;



function WIFIDeviceCreate:PWIFIDevice;
{Create a new WIFI entry}
{Return: Pointer to new WIFI entry or nil if WIFI could not be created}
begin
 {}
 Result:=WIFIDeviceCreateEx(SizeOf(TWIFIDevice));
end;

{==============================================================================}

function WIFIDeviceCreateEx(Size:LongWord):PWIFIDevice;
{Create a new WIFI entry}
{Size: Size in bytes to allocate for new WIFI (Including the WIFI entry)}
{Return: Pointer to new WIFI entry or nil if WIFI could not be created}
begin
 {}
 Result:=nil;

 {Check Size}
 if Size < SizeOf(TWIFIDevice) then Exit;

 {Create WIFI}
 Result:=PWIFIDevice(DeviceCreateEx(Size));
 if Result = nil then Exit;

 {Update Device}
 Result^.Device.DeviceBus:=DEVICE_BUS_NONE;
 Result^.Device.DeviceType:=WIFI_TYPE_SDIO;
 Result^.Device.DeviceFlags:=WIFI_FLAG_NONE;  // may need to change
 Result^.Device.DeviceData:=nil;

 {Update WIFI}
 Result^.WIFIId:=DEVICE_ID_ANY;
// Result^.WIFIState:=WIFI_STATE_EJECTED;
 Result^.DeviceInitialize:=nil;
// Result^.DeviceDeinitialize:=nil;
// Result^.DeviceGetCardDetect:=nil;
// Result^.DeviceGetWriteProtect:=nil;
 Result^.DeviceSendCommand:=nil;
 Result^.DeviceSetIOS:=nil;
 Result^.Lock:=INVALID_HANDLE_VALUE;

 {Create Lock}
 Result^.Lock:=MutexCreateEx(False,MUTEX_DEFAULT_SPINCOUNT,MUTEX_FLAG_RECURSIVE);
 if Result^.Lock = INVALID_HANDLE_VALUE then
  begin
   if WIFI_LOG_ENABLED then WIFILogError(nil,'Failed to create lock for WIFI device');
   WIFIDeviceDestroy(Result);
   Result:=nil;
   Exit;
  end;
end;

function WIFIDeviceDestroy(WIFI:PWIFIDevice):LongWord;
{Destroy an existing WIFI entry}
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;
 if WIFI^.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Check WIFI}
 Result:=ERROR_IN_USE;
 if WIFIDeviceCheck(WIFI) = WIFI then Exit;

 {Check State}
 if WIFI^.Device.DeviceState <> DEVICE_STATE_UNREGISTERED then Exit;

 {Destroy Lock}
 if WIFI^.Lock <> INVALID_HANDLE_VALUE then
  begin
   MutexDestroy(WIFI^.Lock);
  end;

 {Destroy WIFI}
 Result:=DeviceDestroy(@WIFI^.Device);
end;

function WIFIDeviceCheck(WIFI:PWIFIDevice):PWIFIDevice;
{Check if the supplied WIFI device is in the table}
var
 Current:PWIFIDevice;
begin
 {}
 Result:=nil;

 {Check WIFI}
 if WIFI = nil then Exit;
 if WIFI^.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Acquire the Lock}
 if CriticalSectionLock(WIFIDeviceTableLock) = ERROR_SUCCESS then
  begin
   try
    {Get WIFI}
    Current:= WIFIDeviceTable;
    while Current <> nil do
     begin
      {Check WIFI}
      if Current = WIFI then
       begin
        Result:=WIFI;
        Exit;
       end;

      {Get Next}
      Current:=Current^.Next;
     end;
   finally
    {Release the Lock}
    CriticalSectionUnlock(WIFIDeviceTableLock);
   end;
  end;
end;


{Initialization Functions}
procedure WIFIInit;
var
  i : integer;
begin
 {}
 {Check Initialized}
 if WIFIInitialized then Exit;

 {Initialize Logging}
 WIFI_LOG_ENABLED:=(WIFI_DEFAULT_LOG_LEVEL <> WIFI_LOG_LEVEL_NONE);

 {Initialize WIFI Device Table}
 WIFIDeviceTable:=nil;
 WIFIDeviceTableLock:=CriticalSectionCreate;
 WIFIDeviceTableCount:=0;
 if WIFIDeviceTableLock = INVALID_HANDLE_VALUE then
  begin
   if WIFI_LOG_ENABLED then WIFILogError(nil,'Failed to create WIFI device table lock');
  end;

 (* disconnect emmc from SD card (connect sdhost instead) *)
 for i := 48 to 53 do
   GPIOFunctionSelect(i,GPIO_FUNCTION_ALT0);

 (* connect emmc to wifi *)
 for i := 34 to 39 do
 begin
   GPIOFunctionSelect(i,GPIO_FUNCTION_ALT3);

   if (i = 34) then
     GPIOPullSelect(i, GPIO_PULL_NONE)
   else
     GPIOPullSelect(i, GPIO_PULL_UP);
 end;

 // init 32khz oscillator.
 SysGPIOPullSelect(SD_32KHZ_PIN, GPIO_PULL_NONE);
 GPIOFunctionSelect(SD_32KHZ_PIN, GPIO_FUNCTION_ALT0);

 // turn on wlan power
 GPIOFunctionSelect(WLAN_ON_PIN, GPIO_FUNCTION_OUT);
 GPIOOutputSet(WLAN_ON_PIN, GPIO_LEVEL_HIGH);


 {Initialize SDHCI Host Table}
(* SDHCIHostTable:=nil;
 SDHCIHostTableLock:=CriticalSectionCreate;
 SDHCIHostTableCount:=0;
 if SDHCIHostTableLock = INVALID_HANDLE_VALUE then
  begin
   if WIFI_LOG_ENABLED then MMCLogError(nil,'Failed to create SDHCI host table lock');
  end;*)

  SDIOProtect := SpinCreate;

  WIFIInitialized:=True;
end;

function WIFIDeviceSetClock(WIFI:PWIFIDevice;Clock:LongWord):LongWord;
var
 SDHCI:PSDHCIHost;
begin
 {}
 Result:=WIFI_STATUS_INVALID_PARAMETER;

 {Check MMC}
 if WIFI = nil then Exit;

 WIFILogInfo(nil,'WIFI Set Clock (Clock=' + IntToStr(Clock) + ')');

 {Get SDHCI}
 SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
 if SDHCI = nil then Exit;

 wifilogdebug(nil, 'clock='+inttostr(clock) + ' max freq='+inttostr(sdhci^.MaximumFrequency));
 {Check Clock}
 if Clock > SDHCI^.MaximumFrequency then
  begin
   Clock:=SDHCI^.MaximumFrequency;
  end;
 if Clock < SDHCI^.MinimumFrequency then
  begin
   Clock:=SDHCI^.MinimumFrequency;
  end;

 {Set Clock}
 WIFI^.Clock:=Clock;

 {Set IOS}
 Result:=WIFIDeviceSetIOS(WIFI);

 //See: mmc_set_clock in U-Boot mmc.c
 //See:
end;


function WIFIDeviceInitialize(WIFI:PWIFIDevice):LongWord;
{Reference: Section 3.6 of SD Host Controller Simplified Specification V3.0 partA2_300.pdf}
var
 SDHCI:PSDHCIHost;
 Command : TSDIOCommand;
 rcaraw : longword;
 updatevalue : word;
 ioreadyvalue : word;
 chipid : word;
 chipidrev : byte;
 bytevalue : byte;
 blocksize : byte;
 result1, result2 : longword;
 retries : word;
begin
 {}
 try
 WIFI_DEFAULT_LOG_LEVEL:=WIFI_LOG_LEVEL_INFO;

 WIFILogInfo(nil,'WIFI Initialize');

 Result:=WIFI_STATUS_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;

 {Check Initialize}
 if Assigned(WIFI^.DeviceInitialize) then
  begin
   WIFILogDebug(nil,'WIFI^.DeviceInitialize');
   Result:=WIFI^.DeviceInitialize(WIFI);
  end
 else
  begin
   {Default Method}
   {Get SDHCI}
   WIFILogDebug(nil,'Default initialize method');

   SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
   if SDHCI = nil then
   begin
    WIFILogError(nil, 'The SDHCI host is nil');
    Exit;
   end;

   WIFILogInfo(nil,'Set initial power');

   // should already have been done elsewhere.
   {Set Initial Power}
   wifilogDebug(nil, 'sdhci^.voltages is ' + inttostr(sdhci^.voltages) + 'firstbitsetof()='+inttostr(firstbitset(sdhci^.voltages)));
   Result:=SDHCIHostSetPower(SDHCI,FirstBitSet(SDHCI^.Voltages) - 1);
   if Result <> WIFI_STATUS_SUCCESS then
    begin
     WIFILogError(nil,'failed to Set initial power');

     Exit;
    end;

   {Set Initial Clock}
   WIFILogInfo(nil,'Set device clock');
   Result:=WIFIDeviceSetClock(WIFI,SDIO_BUS_SPEED_DEFAULT);
   if Result <> WIFI_STATUS_SUCCESS then
     wifilogError(nil, 'failed to set the clock speed to default')
   else
     wifilogdebug(nil, 'Set device clock succeeded');

   {Perform an SDIO Reset}
   wifiloginfo(nil, 'SDIO WIFI Device Reset');
   SDIOWIFIDeviceReset(WIFI);

   wifiloginfo(nil, 'WIFI Device Go Idle');
   {Set the Card to Idle State}
   Result:= WIFIDeviceGoIdle(WIFI);
   if Result <> WIFI_STATUS_SUCCESS then
    begin
     wifilogerror(nil, 'go idle returned fail but this is expected...');
    end
   else
     wifilogdebug(nil, 'Go Idle succeeded');


   wifiloginfo(nil, 'send interface condition req');
   {Get the Interface Condition}
   SDWIFIDeviceSendInterfaceCondition(WIFI);

   wifiloginfo(nil, 'send operation condition');
   {Check for an SDIO Card}
   if SDIOWIFIDeviceSendOperationCondition(WIFI,True) = WIFI_STATUS_SUCCESS then
    begin
     wifilogdebug(nil, 'send operation condition successful');
    end
    else
      wifilogerror(nil, 'send operation condition failed');

   WIFI^.Device.DeviceBus:=DEVICE_BUS_SD;
   WIFI^.Device.DeviceType:=WIFI_TYPE_SDIO;
   WIFI^.RelativeCardAddress:=0;
   WIFI^.OperationCondition := $200000;

   {$IFDEF MMC_DEBUG}
   if WIFI_LOG_ENABLED then WIFILogDebug(nil,'MMC Initialize Card Type is SDIO');
   {$ENDIF}


   {Get the Operation Condition}
   wifiloginfo(nil, 'get operation condition');
   Result:=SDIOWIFIDeviceSendOperationCondition(WIFI,False);
   if Result <> WIFI_STATUS_SUCCESS then
    begin
//     Exit;
    end;


   wifiloginfo(nil, 'Set card relative address');
   {send CMD3 get relative address}
   FillChar(Command,SizeOf(TSDIOCommand),0);
   Command.Command:=SDIO_CMD_SET_RELATIVE_ADDR;
   Command.Argument:=0;
   Command.ResponseType:=SDIO_RSP_R6;
   Command.Data:=nil;

   Result := WIFIDeviceSendCommand(WIFI, @Command);
   rcaraw := command.response[0];
   WIFI^.RelativeCardAddress := (rcaraw shr 16) and $ff;
   if (Result = WIFI_STATUS_SUCCESS) then
      wifiloginfo(nil,' Card relative address is ' + inttohex((rcaraw shr 16) and $ff, 2))
   else
     wifilogerror(nil, 'Could not set relative card address; error='+inttostr(Result));


   wifiloginfo(nil, 'Selecting wifi device with cmd7');

   FillChar(Command,SizeOf(TSDIOCommand),0);
   Command.Command:= SDIO_CMD_SELECT_CARD;
   Command.Argument:= rcaraw;
   Command.ResponseType:=SDIO_RSP_R1;
   Command.Data:=nil;

   Result := WIFIDeviceSendCommand(WIFI, @Command);

   if (Result = WIFI_STATUS_SUCCESS) then
   begin
     wifilogdebug(nil, 'Device successfully selected response[0]=' + inttohex(command.response[0], 8));
     // for an I/O only card, the status bits are fixed at 0x0f (bits 12:9 of response[0])
     if (((command.response[0] shr 9) and $f) = $f) then
       wifilogdebug(nil, 'The card correctly reads as I/O only')
     else
       wifilogerror(nil, 'Something went wrong with the status bits');
   end
   else
     wifilogerror(nil, 'Failed to select the card at rca='+inttohex((rcaraw shr 16) and $ff, 8));

   {Set Clock to high speed}
   WIFILogInfo(nil,'Set device clock');
   Result:=WIFIDeviceSetClock(WIFI,SDIO_BUS_SPEED_HS);
   if Result <> WIFI_STATUS_SUCCESS then
     wifilogError(nil, 'failed to set the clock speed to default')
   else
     wifilogdebug(nil, 'Set device clock succeeded');

   wifiloginfo(nil, 'setting bus speed via common control registers');

   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite,BUS_FUNCTION,SDIO_CCCR_SPEED,3,nil);            // emmc sets this to 2.
   if (Result = WIFI_STATUS_SUCCESS) then
     wifilogdebug(nil, 'Successfully updated bus speed register')
   else
     wifilogerror(nil, 'Failed to update bus speed register');


   wifiloginfo(nil, 'setting bus interface via common control registers');

   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite,BUS_FUNCTION,SDIO_CCCR_IF, $2,nil);
   if (Result = WIFI_STATUS_SUCCESS) then
     wifilogdebug(nil, 'Successfully updated bus interface control')
   else
     wifilogerror(nil, 'Failed to update bus interface control');

   wifiloginfo(nil,'Waiting until the backplane is ready');
   blocksize := 0;
   retries := 0;
   repeat
     // attempt to set and read back the fn0 block size.
     result1 := SDIOWIFIDeviceReadWriteDirect(WIFI, sdioWrite, BUS_FUNCTION, SDIO_CCCR_BLKSIZE, WIFI_BAK_BLK_BYTES, nil);
     result2 := SDIOWIFIDeviceReadWriteDirect(WIFI, sdioRead, BUS_FUNCTION, SDIO_CCCR_BLKSIZE, 1, @blocksize);
     retries += 1;
     sleep(1);
   until ((result1 = WIFI_STATUS_SUCCESS) and (result2 = WIFI_STATUS_SUCCESS) and (blocksize = WIFI_BAK_BLK_BYTES)) or (retries > 500);

   if (retries > 500) then
     wifilogerror(nil, 'the backplane was not ready');

   // if we get here we have successfully set the fn0 block size in CCCR and therefore the backplane is up.

   wifiloginfo(nil, 'setting backplane block size');

   // set block sizes for fn1 and fn2 in their respective function registers.
   // note these are still writes to the common IO area (function 0).
   updatevalue := WIFI_BAK_BLK_BYTES;
   wifiloginfo(nil, 'setting backplane fn1 block size to 64');
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BUS_FUNCTION, BUS_BAK_BLKSIZE_REG, updatevalue and $ff,nil);
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BUS_FUNCTION, BUS_BAK_BLKSIZE_REG+1,(updatevalue shr 8) and $ff,nil);

   wifiloginfo(nil, 'setting backplane fn2 (radio) block size to 512');
   updatevalue := 512;
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BUS_FUNCTION, BUS_RAD_BLKSIZE_REG, updatevalue and $ff,nil);
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BUS_FUNCTION, BUS_RAD_BLKSIZE_REG+1,(updatevalue shr 8) and $ff,nil);

   // we only check the last result here. Needs changing really.
   if (Result = WIFI_STATUS_SUCCESS) then
     wifilogdebug(nil, 'Successfully updated backplane block sizes')
   else
     wifilogerror(nil, 'Failed to update backplane block sizes');

   wifiloginfo(nil, 'IO Enable backplane function 1');
   ioreadyvalue := 0;
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite,BUS_FUNCTION,SDIO_CCCR_IOEx, 1 shl 1,nil);
   if (Result = WIFI_STATUS_SUCCESS) then
     wifilogdebug(nil, 'io enable successfully set for function 1')
   else
     wifilogerror(nil, 'io enable could not be set for function 1');

   // at this point ether4330.c turns off all interrupts and then does to ioready check below.

   WIFILogInfo(nil, 'Waiting for IOReady function 1');
   ioreadyvalue := 0;
   while (ioreadyvalue and (1 shl 1)) = 0 do
   begin
     Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BUS_FUNCTION, SDIO_CCCR_IORx,  0, @ioreadyvalue);
     if (Result <> WIFI_STATUS_SUCCESS) then
     begin
       wifilogerror(nil, 'Could not read IOReady value');
       exit;
     end;
     sleep(10);
   end;

   wifilogdebug(nil, 'Reading the Chip ID');
   chipid := 0;
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BACKPLANE_FUNCTION,0,  0, @chipid);
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BACKPLANE_FUNCTION,1,  0, pbyte(@chipid)+1);
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BACKPLANE_FUNCTION,2,  0, @chipidrev);
   chipidrev := chipidrev and $f;
   if (Result = WIFI_STATUS_SUCCESS) then
   begin
     wifiloginfo(nil, 'WIFI Chip ID is 0x'+inttohex(chipid, 4) + ' rev ' + inttostr(chipidrev));
     WIFI^.chipid := chipid;
     WIFI^.chipidrev := chipidrev;
   end;


   // scan the cores to establish various key addresses
   WIFIDeviceCoreScan(WIFI);

   if (WIFI^.armctl = 0) or (WIFI^.dllctl = 0) or
     ((WIFI^.armcore = ARMcm3) and ((WIFI^.socramctl = 0) or (WIFI^.socramregs = 0))) then
   begin
     WIFILogError(nil, 'Corescan did not find essential cores!');
     exit;
   end;


   WIFILogDebug(nil, 'Disable core');
   if (WIFI^.armcore = ARMcr4) then
   begin
     wifilogdebug(nil, 'sbreset armcr4 core');
     sbreset(WIFI, WIFI^.armctl, Cr4Cpuhalt, Cr4CpuHalt)
   end
   else
   begin
     wifilogdebug(nil, 'sbdisable armctl core');
     sbdisable(WIFI, WIFI^.armctl, 0, 0);
   end;

   sbreset(WIFI, WIFI^.dllctl, 8 or 4, 4);

   WIFILogInfo(nil, 'Device RAM scan');

   WIFIDeviceRamScan(WIFI);


   // Set clock on function 1
   Result := SDIOWIFIDeviceReadWriteDirect(WIFI, sdioWrite, BACKPLANE_FUNCTION, BAK_CHIP_CLOCK_CSR_REG, 0, nil);
   if (Result <> WIFI_STATUS_SUCCESS) then
     WIFILogError(nil, 'Unable to update config at chip clock csr register');
   MicrosecondDelay(10);

   // check active low power clock availability

   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BACKPLANE_FUNCTION, BAK_CHIP_CLOCK_CSR_REG, 0, nil);
   sleep(1);
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BACKPLANE_FUNCTION, BAK_CHIP_CLOCK_CSR_REG, Nohwreq or ReqALP, nil);

   // now we keep reading them until we have some availability
   bytevalue := 0;
   while (bytevalue and (HTavail or ALPavail) = 0) do
   begin
     Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead, BACKPLANE_FUNCTION, BAK_CHIP_CLOCK_CSR_REG, 0, @bytevalue);
     if (Result <> WIFI_STATUS_SUCCESS) then
       wifilogerror(nil, 'failed to read clock settings');
     MicrosecondDelay(10);
   end;

   WIFILogDebug(nil, 'Clock availability is 0x' + inttohex(bytevalue, 2));

   // finally we can clear active low power request. Not sure if any of this is needed to be honest.
   wifiloginfo(nil, 'clearing active low power clock request');
   Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BACKPLANE_FUNCTION, BAK_CHIP_CLOCK_CSR_REG, Nohwreq or ForceALP, nil);

   MicrosecondDelay(65);

  WIFIDeviceSetBackplaneWindow(WIFI, WIFI^.chipcommon);

  WIFILogInfo(nil, 'Disable pullups');
  Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BACKPLANE_FUNCTION, gpiopullup, 0, nil);
  if (Result = WIFI_STATUS_SUCCESS) then
    WIFILogDebug(nil, 'Successfully disabled SDIO extra pullups')
  else
    wifilogerror(nil, 'Failed to disable SDIO extra pullups');

  Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BACKPLANE_FUNCTION, Gpiopulldown, 0, nil);
  if (Result = WIFI_STATUS_SUCCESS) then
    wifilogDebug(nil, 'Successfully disabled SDIO extra pulldowns')
  else
    wifilogerror(nil, 'Failed to disable SDIO extra pulldowns');


   if (WIFI^.chipid = $4330) or (WIFI^.chipid = 43362) then
   begin
    // there is other stuff from sbinit() to do here
    // however the chipids are not either 3b or zero as far as I can tell so
    // we won't do them until we find a device that needs them.
    // relates to power management by the look of it. PMU, drive strength.
   end;


   WIFILogInfo(nil, 'Download WIFI firmware');
   Result := WIFIDeviceDownloadFirmware(WIFI);

   // Enable the device. This should boot the firmware we just loaded to the chip
   sbenable(WIFI);

   wifiloginfo(nil, 'Enabling interrupts for all functions');
   Result := SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BUS_FUNCTION, SDIO_CCCR_IENx, (INTR_CTL_MASTER_EN or INTR_CTL_FUNC1_EN or INTR_CTL_FUNC2_EN), nil );
   if (Result = WIFI_STATUS_SUCCESS) then
     WIFILogDebug(nil, 'Successfully enabled interrupts')
   else
     wifilogerror(nil, 'Failed  to enable interrupts');



   // create the receive thread but it should be created suspended. We'll activate
   // it once the wifi device has been initialized properly.
   // this code is temporary - it will need to be moved into the unit initialization
   // eventually, as will creation of the actual wifi device.

   WIFILogInfo(nil, 'Creating WIFI Worker Thread');

   WIFIWorkerThread := TWIFIWorkerThread.Create(true, WIFI);
   WIFIWorkerThread.Start;

    // again, this code does not belong here and will be moved later.
   WirelessInit(WIFI);

   Result:=WIFI_STATUS_SUCCESS;
  end;

 except
   on e : exception do
   wifilogerror(nil, 'Exception ' + e.message + ' at ' + inttohex(longword(exceptaddr), 8) + ' during wifiinitialize');
 end;
end;

function WIFIDeviceSetBackplaneWindow(WIFI : PWIFIDevice; addr : longword) : longword;
begin
 addr := addr and (not $7fff);

 WIFILogDebug(nil, 'setting backplane address to ' + inttohex((addr shr 8) and $ff, 8) + ' '
                  + inttohex((addr shr 16) and $ff, 8) + ' '
                  + inttohex((addr shr 24) and $ff, 8));

 Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BACKPLANE_FUNCTION, BAK_WIN_ADDR_REG, (addr shr 8) and $ff,nil);
 Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BACKPLANE_FUNCTION, BAK_WIN_ADDR_REG+1,(addr shr 16) and $ff,nil);
 Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BACKPLANE_FUNCTION, BAK_WIN_ADDR_REG+2,(addr shr 24) and $ff,nil);

 if (Result = WIFI_STATUS_SUCCESS) then
   WIFILogDebug(nil, 'function ' + inttostr(1) + ' backplanewindow updated to ' + inttohex(addr, 8))
 else
   wifilogerror(nil, 'something went wrong in setbackplanewindow');
end;

function WIFIDeviceRegister(WIFI:PWIFIDevice):LongWord;
{Register a new WIFI device in the table}
var
 WIFIId:LongWord;
begin
 {}
 Result:=ERROR_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;
 if WIFI^.WIFIId <> DEVICE_ID_ANY then Exit;
 if WIFI^.Device.Signature <> DEVICE_SIGNATURE then Exit;

 {Check WIFI}
 Result:=ERROR_ALREADY_EXISTS;
 if WIFIDeviceCheck(WIFI) = WIFI then Exit;

 {Check State}
 if WIFI^.Device.DeviceState <> DEVICE_STATE_UNREGISTERED then Exit;

 {Insert WIFI}
 if CriticalSectionLock(WIFIDeviceTableLock) = ERROR_SUCCESS then
  begin
   try
    {Update WIFI}
    WIFIId:=0;
    while WIFIDeviceFind(WIFIId) <> nil do
     begin
      Inc(WIFIId);
     end;
    WIFI^.WIFIId:=WIFIId;

    {Update Device}
    WIFI^.Device.DeviceName:=WIFI_NAME_PREFIX + IntToStr(WIFI^.WIFIId);
    WIFI^.Device.DeviceClass:=DEVICE_CLASS_SD;

    {Register Device}
    Result:=DeviceRegister(@WIFI^.Device);
    WIFILogError(nil, 'deviceregister result = ' + inttostr(result));
    if Result <> ERROR_SUCCESS then
     begin
      WIFI^.WIFIId:=DEVICE_ID_ANY;
      Exit;
     end;

    {Link WIFI}
    if WIFIDeviceTable = nil then
     begin
      WIFIDeviceTable:=WIFI;
     end
    else
     begin
      WIFI^.Next:=WIFIDeviceTable;
      WIFIDeviceTable^.Prev:=WIFI;
      WIFIDeviceTable:=WIFI;
     end;

    {Increment Count}
    Inc(WIFIDeviceTableCount);

    {Return Result}
    Result:=ERROR_SUCCESS;
   finally
    CriticalSectionUnlock(WIFIDeviceTableLock);
   end;
  end
 else
  begin
   Result:=ERROR_CAN_NOT_COMPLETE;
  end;
end;

function WIFIDeviceFind(WIFIId:LongWord):PWIFIDevice;
var
 WIFI:PWIFIDevice;
begin
 {}
 Result:=nil;

 {Check Id}
 if WIFIId = DEVICE_ID_ANY then Exit;

 {Acquire the Lock}
 if CriticalSectionLock(WIFIDeviceTableLock) = ERROR_SUCCESS then
  begin
   try
    {Get WIFI}
    WIFI:=WIFIDeviceTable;
    while WIFI <> nil do
     begin
      {Check State}
      if WIFI^.Device.DeviceState = DEVICE_STATE_REGISTERED then
       begin
        {Check Id}
        if WIFI^.WIFIId = WIFIId then
         begin
          Result:=WIFI;
          Exit;
         end;
       end;

       {Get Next}
      WIFI:=WIFI^.Next;
     end;
   finally
    {Release the Lock}
    CriticalSectionUnlock(WIFIDeviceTableLock);
   end;
  end;
end;

function SDIOWIFIDeviceReset(WIFI:PWIFIDevice):LongWord;
{See: SDIO Simplified Specification V2.0, 4.4 Reset for SDIO}
var
 Abort:Byte;
 Status:LongWord;
begin
 {}
 WIFILogDebug(WIFI, 'SDIO WIFI Reset');

 Result:=WIFI_STATUS_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;

 {Get Abort Value}
 WIFILogDebug(WIFI, 'get abort value');

 Status:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BUS_FUNCTION,SDIO_CCCR_ABORT,0,@Abort);
 MicrosecondDelay(20000);
 if Status <> WIFI_STATUS_SUCCESS then
  begin
   WIFILogDebug(WIFI, 'WIFI Device Reset - SDIO_CCR_ABORT returned non zero result of ' + inttostr(status));

   Abort:=$08;
  end
 else
  begin
   WIFILogDebug(nil, 'abort value success status');
   Abort:=Abort or $08;
  end;

 {Set Abort Value}
 WIFILogDebug(WIFI, 'Set abort value');
 Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite,BUS_FUNCTION,SDIO_CCCR_ABORT,Abort,nil);
 MicrosecondDelay(20000);
 WIFILogDebug(WIFI, 'Result of setting abort='+inttostr(Result));

 //See: sdio_reset in \linux-rpi-3.18.y\drivers\mmc\core\sdio_ops.c
 //
end;

function WIFIDeviceGoIdle(WIFI:PWIFIDevice):LongWord;
var
 Status:LongWord;
 Command:TSDIOCommand;
begin
 {}
 Result:=WIFI_STATUS_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;

 WIFILogDebug(nil,'WIFI Go Idle');

 {Delay 1ms}
 MicrosecondDelay(1000);

 {Setup Command}
 FillChar(Command,SizeOf(TSDIOCommand),0);
 Command.Command:=SDIO_CMD_GO_IDLE_STATE;
 Command.Argument:=0;
 Command.ResponseType:=SDIO_RSP_R1;
 Command.Data:=nil;

 {Send Command}
 Status:=WIFIDeviceSendCommand(WIFI,@Command);
 if Status <> WIFI_STATUS_SUCCESS then
  begin
   WIFILogDebug(nil,'WIFI failed to go idle');

   Result:=Status;
   Exit;
  end;

 WIFILogDebug(nil, 'WIFI successfully went idle');

 {Delay 2ms}
 MicrosecondDelay(2000);

 Result:=WIFI_STATUS_SUCCESS;

 //See: mmc_go_idle in U-Boot mmc.c
 //     mmc_go_idle in \linux-rpi-3.18.y\drivers\mmc\core\mmc_ops.c
end;

function SDWIFIDeviceSendInterfaceCondition(WIFI:PWIFIDevice):LongWord;
{See: 4.3.13 of SD Physical Layer Simplified Specification V4.10

 CMD8 (SEND_IF_COND) must be invoked to support SD 2.0 cards
 The card must be in Idle State before issuing this command

 This command will fail harmlessly for SD 1.0 cards
}
var
 Status:LongWord;
 SDHCI:PSDHCIHost;
 Command:TSDIOCommand;
begin
 {}
 Result:=WIFI_STATUS_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;

 WIFILogDebug(nil,'SD Send Interface Condition');

 {Get SDHCI}
 SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
 if SDHCI = nil then Exit;

 {Setup Command}
 FillChar(Command,SizeOf(TSDIOCommand),0);
 Command.Command:=SDIO_CMD_SEND_IF_COND;
 Command.Argument:=SDIO_SEND_IF_COND_CHECK_PATTERN;
 if (SDHCI^.Voltages and SDIO_SEND_IF_COND_VOLTAGE_MASK) <> 0 then
  begin
   {Set bit 8 if the host supports voltages between 2.7 and 3.6 V}
   Command.Argument:=(1 shl 8) or SDIO_SEND_IF_COND_CHECK_PATTERN;
  end;
 Command.ResponseType:=SDIO_RSP_R7;
 Command.Data:=nil;

 {Send Command}
 Status:=WIFIDeviceSendCommand(WIFI,@Command);
 if Status <> WIFI_STATUS_SUCCESS then
  begin
   Result:=Status;
   Exit;
  end;

 {Check Response}
   if (Command.Response[0] and $FF) <> SDIO_SEND_IF_COND_CHECK_PATTERN then
    begin
     wifilogError(nil,'SD Send Interface Condition failure (Response=' + IntToHex(Command.Response[0] and $FF,8) + ')');
     Exit;
    end
    else
      WIFILogDebug(nil, 'WIFI Send interface condition check pattern matches');

   {Get Response}
   WIFILogDebug(nil,'WIFI Send Interface Condition Response0=' + IntToHex(Command.Response[0] and $FF,8)
     + 'Response1=' + IntToHex(Command.Response[1] and $FF,8));
   WIFI^.InterfaceCondition:=Command.Response[0];

 Result:=WIFI_STATUS_SUCCESS;

 //See: mmc_send_if_cond in U-Boot mmc.c
 //See: mmc_send_if_cond in \linux-rpi-3.18.y\drivers\mmc\core\sd_ops.c
end;


function SDIOWIFIDeviceSendOperationCondition(WIFI:PWIFIDevice;Probe:Boolean):LongWord;
var
 Status:LongWord;
 Timeout:Integer;
 SDHCI:PSDHCIHost;
 Command:TSDIOCommand;
begin
 {}
 Result:=WIFI_STATUS_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;

 {$IFDEF MMC_DEBUG}
 if WIFI_LOG_ENABLED then WIFILogDebug(nil,'SDIO Send Operation Condition');
 {$ENDIF}

 {Get SDHCI}
 SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
 if SDHCI = nil then Exit;

 {Setup Command}
 FillChar(Command,SizeOf(TSDIOCommand),0);
 Command.Command:=SDIO_CMD_SEND_OP_COND;
 Command.Argument:=0;
 if not(Probe) then
   Command.Argument:=WIFI^.OperationCondition;

 Command.ResponseType:=SDIO_RSP_R4;
 Command.Data:=nil;

 {Setup Timeout}
 Timeout:=100;
 WIFILogDebug(nil, 'waiting for non-busy signal from wifi device');
 while Timeout > 0 do
  begin
   {Send Command}
   Status:=WIFIDeviceSendCommand(WIFI,@Command);
   if Status <> WIFI_STATUS_SUCCESS then
    begin
     wifilogerror(nil, 'sendoperationcondition devicesendcommand returned failed status ' + inttostr(status));
     Result:=Status;
     Exit;
    end;

   {Single pass only on probe}
   if Probe then Break;

   if (Command.Response[0] and WIFI_OCR_BUSY) <> 0 then Break;

   Dec(Timeout);
   if Timeout = 0 then
    begin
     if WIFI_LOG_ENABLED then WifiLogError(nil,'SDIO Send Operation Condition Busy Status Timeout');
     Exit;
    end;
   MillisecondDelay(10);
  end;

 WIFILogDebug(nil, 'wifi device is ready for action');


 {Get Response}
  WIFILogDebug(nil, 'operation condition returned as ' + inttostr(command.response[0]));
  WIFI^.OperationCondition:=Command.Response[0];
  //To Do //SD_OCR_CCS etc (see: MMC/SD)

  Result:=WIFI_STATUS_SUCCESS;

  //See: mmc_send_io_op_cond in \linux-rpi-3.18.y\drivers\mmc\core\sdio_ops.c
end;

function WIFIDeviceSetIOS(WIFI:PWIFIDevice):LongWord;
var
 Value:Byte;
 SDHCI:PSDHCIHost;
begin
 {}
 Result:=WIFI_STATUS_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;

 WIFILogDebug(nil,'WIFI Set IOS');

 {Check Set IOS}
 if Assigned(WIFI^.DeviceSetIOS) then
  begin
   Result:=WIFI^.DeviceSetIOS(WIFI);
  end
 else
  begin
   {Default Method}
   {Get SDHCI}
   SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
   if SDHCI = nil then Exit;

   {Set Control Register}
   SDHCIHostSetControlRegister(SDHCI);

   {Check Clock}
   if WIFI^.Clock <> SDHCI^.Clock then
    begin
     SDHCIHostSetClock(SDHCI,WIFI^.Clock);
     SDHCI^.Clock:=WIFI^.Clock;
    end;

   {Set Power}
   SDHCIHostSetPower(SDHCI,FirstBitSet(SDHCI^.Voltages) - 1);

   {Set Bus Width}
   WIFI^.BusWidth := WIFI_BUS_WIDTH_4;
   Value:=SDHCIHostReadByte(SDHCI,SDHCI_HOST_CONTROL);
(*   if WIFI^.BusWidth = WIFI_BUS_WIDTH_8 then
    begin
     Value:=Value and not(SDHCI_CTRL_4BITBUS);
     if (SDHCIGetVersion(SDHCI) >= SDHCI_SPEC_300) or ((SDHCI^.Quirks2 and SDHCI_QUIRK2_USE_WIDE8) <> 0) then
      begin
       Value:=Value or SDHCI_CTRL_8BITBUS;
      end;
    end
   else
    begin*)
     if SDHCIGetVersion(SDHCI) >= SDHCI_SPEC_300 then
      begin
       wifilogdebug(nil, 'turn off 8 bit bus');
       Value:=Value and not(SDHCI_CTRL_8BITBUS);
      end;

     if WIFI^.BusWidth = WIFI_BUS_WIDTH_4 then
      begin
       wifilogdebug(nil, 'set 4 bit bus');
       Value:=Value or SDHCI_CTRL_4BITBUS;
      end
     else
      begin
       wifilogdebug(nil, 'turn off 4 bit bus');
       Value:=Value and not(SDHCI_CTRL_4BITBUS);
      end;
    (*end;*)

   // block gap control
   SDHCIHostWriteByte(SDHCI, SDHCI_BLOCK_GAP_CONTROL, 0);
   SDHCIHostWriteByte(SDHCI, SDHCI_POWER_CONTROL, 0);

   {Check Clock}
   if WIFI^.Clock > 26000000 then
    begin
     Value:=Value or SDHCI_CTRL_HISPD;
    end
   else
    begin
     Value:=Value and not(SDHCI_CTRL_HISPD);
    end;
   if (SDHCI^.Quirks and SDHCI_QUIRK_NO_HISPD_BIT) <> 0 then
    begin
     Value:=Value and not(SDHCI_CTRL_HISPD);
    end;
   //To Do //More here (Reset SD Clock Enable / Re-enable SD Clock) //See: bcm2835_mmc_set_ios in \linux-rpi-3.18.y\drivers\mmc\host\bcm2835-mmc.c
                 //Even more quirks                                       //See: sdhci_do_set_ios in \linux-rpi-3.18.y\drivers\mmc\host\sdhci.c
   SDHCIHostWriteByte(SDHCI,SDHCI_HOST_CONTROL,Value);

   Result:=WIFI_STATUS_SUCCESS;
  end;

 //See: mmc_set_ios in mmc.c
 //     sdhci_set_ios in sdhci.c
 //See: bcm2835_mmc_set_ios in \linux-rpi-3.18.y\drivers\mmc\host\bcm2835-mmc.c
 //     sdhci_do_set_ios in \linux-rpi-3.18.y\drivers\mmc\host\sdhci.c
end;


function SDIOWIFIDeviceReadWriteDirect(WIFI:PWIFIDevice; Direction : TSDIODirection; Operation,Address:LongWord; Input:Byte; Output:PByte):LongWord;
var
 Status:LongWord;
 SDHCI:PSDHCIHost;
 Command:TSDIOCommand;
begin
 {}
 SpinLock(SDIOProtect);
 try

   Result:=WIFI_STATUS_INVALID_PARAMETER;

   {Check WIFI}
   if WIFI = nil then Exit;

   WIFILogDebug(nil,'sdio read write direct address='+inttohex(address, 8) + ' value='+inttohex(input, 2));

   {$IFDEF MMC_DEBUG}
   if WIFI_LOG_ENABLED then WIFILogDebug(nil,'SDIO Read Write Direct');
   {$ENDIF}

   {Get SDHCI}
   WIFILogDebug(nil,'get sdhci');

   SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
   if SDHCI = nil then Exit;

   {Check Operation}
   if Operation > 7 then Exit;

   {Check Address}
   if (Address and not($0001FFFF)) <> 0 then Exit;

   WIFILogDebug(nil,'setup command');

   {Setup Command}
   FillChar(Command,SizeOf(TSDIOCommand),0);
   Command.Command:=SDIO_CMD_RW_DIRECT;
   Command.Argument:=0;
   Command.ResponseType:=SDIO_RSP_R5;
   Command.Data:=nil;

   WIFILogDebug(nil,'setup argument. direction='+inttostr(ord(direction)) +'[0=read, 1=write]');

   {Setup Argument}
   if Direction = sdioWrite then Command.Argument:=$80000000;
   Command.Argument:=Command.Argument or (Operation shl 28);
   if (Direction = sdioWrite) and (Output <> nil) then Command.Argument:=Command.Argument or $08000000;
   Command.Argument:=Command.Argument or (Address shl 9);
   Command.Argument:=Command.Argument or Input;

   WIFILogDebug(nil,'send command. argument ended up being ' + inttohex(command.argument, 8));

   {Send Command}
   Status:=WIFIDeviceSendCommand(WIFI,@Command);
   if Status <> WIFI_STATUS_SUCCESS then
    begin
     WIFILogDebug(nil,'status is not success (=' + inttostr(result) + ')');

     Result:=Status;
     Exit;
    end;

   {Check Result}
   WIFILogDebug(nil,'check result (response[0]='+inttostr(command.response[0]));

   if (Command.Response[0] and SDIO_RSP_R5_ERROR) <> 0 then Exit;
   if (Command.Response[0] and SDIO_RSP_R5_FUNCTION_NUMBER) <> 0 then Exit;
   if (Command.Response[0] and SDIO_RSP_R5_OUT_OF_RANGE) <> 0 then Exit;

   {Get Output}
   if Output <> nil then
    begin
       WIFILogDebug(nil,'get output');
       Output^:=Command.Response[0] and $FF;
    end;

   Result:=WIFI_STATUS_SUCCESS;

 finally
   SpinUnlock(SDIOProtect);
 end;

 //See: mmc_io_rw_direct_host in \linux-rpi-3.18.y\drivers\mmc\core\sdio_ops.c
 //
end;

{SDIO_CMD_RW_DIRECT argument format:
      [31] R/W flag
      [30:28] Function number
      [27] RAW flag
      [25:9] Register address
      [7:0] Data}

function SDIOWIFIDeviceReadWriteExtended(WIFI:PWIFIDevice;
            Direction: TSDIODirection;
            Operation, Address : LongWord;
            Increment : Boolean; Buffer : Pointer;
            BlockCount, BlockSize : LongWord;callerid:integer=0) : LongWord;
var
 Status:LongWord;
 SDHCI:PSDHCIHost;
 Command:TSDIOCommand;
 SDIOData : TSDIOData;
 TxSDIOData : TSDIOData;
begin
 {}
 SpinLock(SDIOProtect);
 try
   Result:=WIFI_STATUS_INVALID_PARAMETER;

   {Check WIFI}
   if WIFI = nil then Exit;

   if (operation = 2) then
   WIFILogDebug(nil,'SDIOReadWriteExtended ' + inttostr(ord(direction)) + '[0=read, 1=write] ' + inttostr(operation)
     + ' address=0x' + inttohex(address, 8)
     + ' buf=0x'+inttohex(longword(buffer), 8)
     + ' blockcount='+inttostr(blockcount)
     + ' blocksize='+inttostr(blocksize)
     + ' callerid='+inttostr(callerid));

   {Get SDHCI}
   SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
   if SDHCI = nil then Exit;

   WIFILogDebug(nil, 'check operation; operation='+inttostr(operation));
   {Check Operation}
   if Operation > 7 then Exit;

   WIFILogDebug(nil, 'check address='+inttohex(address, 8));
   {Check Address}
   if (Address and not($0001FFFF)) <> 0 then Exit;

   WIFILogDebug(nil,'setup command');

   {Setup Command}
   FillChar(Command,SizeOf(TSDIOCommand),0);
   Command.Command:=SDIO_CMD_RW_EXTENDED;
   Command.Argument:=0;
   Command.ResponseType:=SDIO_RSP_R1;
   Command.Data:=nil;

   Command.Data := @SDIOData;
   SDIOData.Data := Buffer;

   SDIOData.Blocksize := BlockSize;
   SDIOData.BlockCount := blockcount;

   if (direction = sdioWrite) then
     SDIOData.Flags := WIFI_DATA_WRITE
   else
     SDIOData.Flags := WIFI_DATA_READ;

   WIFILogDebug(nil,'setup argument. write='+inttostr(ord(direction)) + '0=read, 1=write');

   {SDIO_CMD_RW_EXTENDED argument format:
         [31] R/W flag
         [30:28] Function number
         [27] Block mode
         [26] Increment address
         [25:9] Register address
         [8:0] Byte/block count}

   {Setup Argument}
   if (direction = sdioWrite) then
      wifilogdebug(nil, 'adding write but to argument')
   else
     wifilogdebug(nil, 'the argument is configured as a read');
   if (direction = sdioWrite) then Command.Argument:=$80000000;
   Command.Argument:=Command.Argument or (Operation shl 28);   // adds in function number
   if increment then
      Command.Argument := Command.Argument or (1 shl 26);     // add in increment flag
   Command.Argument:=Command.Argument or (Address shl 9);

   if (blockcount = 0) then
     Command.Argument := Command.Argument or BlockSize        // byte mode; blocksize=bytes
   else
   begin
     Command.Argument := Command.Argument or (1 shl 27);      // set block mode bit
     Command.Argument := Command.Argument or BlockCount;
   end;

   WIFILogDebug(nil,'send command. argument ended up being ' + inttohex(command.argument, 8));

   Status:=WIFIDeviceSendCommand(WIFI,@Command);  // send command

   if Status <> WIFI_STATUS_SUCCESS then
    begin
     WIFILogDebug(nil,'status is not success (=' + inttostr(result) + ')');

     Result:=Status;
     Exit;
    end;

   {Check Result}
   WIFILogDebug(nil,'check result command.response[0]='+inttohex(command.response[0], 8));

   if (Command.Response[0] and SDIO_RSP_R5_ERROR) <> 0 then
    begin
     WIFILogDebug(nil, 'command response contains R5 Error');
     Exit;
    end;
   if (Command.Response[0] and SDIO_RSP_R5_FUNCTION_NUMBER) <> 0 then
    begin
     WIFILogDebug(nil, 'command response contains R5 function number');
     Exit;
    end;
   if (Command.Response[0] and SDIO_RSP_R5_OUT_OF_RANGE) <> 0 then
    begin
     WIFILogDebug(nil, 'command response contains R5 out of range');
     Exit;
    end;

   WIFILogDebug(nil,'returning success');

   Result:=WIFI_STATUS_SUCCESS;

 finally
   SpinUnlock(SDIOProtect);
 end;

 //See: mmc_io_rw_extended in \linux-rpi-3.18.y\drivers\mmc\core\sdio_ops.c
 //
end;


function WIFIDeviceSendCommand(WIFI:PWIFIDevice;Command:PSDIOCommand; txdata : PSDIOData = nil):LongWord;
var
 Mask:LongWord;
 TransferMode:LongWord;
 Flags:LongWord;
 Status:LongWord;
 Timeout:LongWord;
 SDHCI:PSDHCIHost;
 blksizecnt : longword;
 SDIODataP : PSDIOData;
begin
 {}
 Result:=WIFI_STATUS_INVALID_PARAMETER;

 {Check WIFI}
 if WIFI = nil then Exit;

 WIFILogDebug(nil,'WIFI Send Command ' + inttostr(command^.Command) + ' status='+inttostr(command^.Status));

 {Check Send Command}
 if Assigned(WIFI^.DeviceSendCommand) then
  begin
   WIFILogDebug(nil,'Assigned wifi sendcommand true');

   Result:=WIFI^.DeviceSendCommand(WIFI,Command);
  end
 else
  begin
   {Default Method}
   {Check Command}
   if Command = nil then Exit;

   {Get SDHCI}
   SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
   if SDHCI = nil then Exit;

   {Acquire the Lock}
   if MutexLock(WIFI^.Lock) = ERROR_SUCCESS then
    begin
     try
      {Setup Status}
      Command^.Status:=WIFI_STATUS_NOT_PROCESSED;
      try
       {Wait Timeout (10ms)}
       Timeout:=1000;
       Mask:=SDHCI_CMD_INHIBIT;
       if (Command^.Data <> nil) or ((Command^.ResponseType and SDIO_RSP_BUSY) <> 0) then
        begin
         Mask:=Mask or SDHCI_DATA_INHIBIT;
        end;

       {We shouldn't wait for data inihibit for stop commands, even though they might use busy signaling}
       if Command^.Command = SDIO_CMD_STOP_TRANSMISSION then
        begin
         Mask:=Mask and not(SDHCI_DATA_INHIBIT);
        end;

       {Wait for Command Inhibit and optionally Data Inhibit to be clear}
       while (SDHCIHostReadLong(SDHCI,SDHCI_PRESENT_STATE) and Mask) <> 0 do
        begin
         if Timeout = 0 then
          begin
           WIFILogError(nil,'WIFI Send Command Inhibit Timeout');
           Command^.Status:=WIFI_STATUS_TIMEOUT;
           Exit;
          end;

         Dec(Timeout);
         MicrosecondDelay(10);
        end;

       {Check Response Type}
       if ((Command^.ResponseType and SDIO_RSP_136) <> 0) and ((Command^.ResponseType and SDIO_RSP_BUSY) <> 0) then
        begin
         if WIFI_LOG_ENABLED then WifiLogError(nil,'MMC Send Command Invalid Response Type');
         Command^.Status:=WIFI_STATUS_INVALID_PARAMETER;
         Exit;
        end;

       {Setup Command Flags}
       if (Command^.ResponseType and SDIO_RSP_PRESENT) = 0 then
        begin
         Flags:=SDHCI_CMD_RESP_NONE;
        end
       else if (Command^.ResponseType and SDIO_RSP_136) <> 0 then
        begin
         Flags:=SDHCI_CMD_RESP_LONG;
        end
       else if (Command^.ResponseType and SDIO_RSP_BUSY) <> 0 then
        begin
         Flags:=SDHCI_CMD_RESP_SHORT_BUSY;
        end
       else
        begin
         Flags:=SDHCI_CMD_RESP_SHORT;
        end;

       if (Command^.ResponseType and SDIO_RSP_CRC) <> 0 then
        begin
         Flags:=Flags or SDHCI_CMD_CRC;
        end;
       if (Command^.ResponseType and SDIO_RSP_OPCODE) <> 0 then
        begin
         Flags:=Flags or SDHCI_CMD_INDEX;
        end;
       {CMD19 is special in that the Data Present Select should be set}
       if (Command^.Data <> nil) or (Command^.Command = SDIO_CMD_SEND_TUNING_BLOCK) or (Command^.Command = SDIO_CMD_SEND_TUNING_BLOCK_HS200) then
        begin
         WIFILogDebug(nil, 'adding sdhci_cmd_data flag to the flags for this command');
         Flags:=Flags or SDHCI_CMD_DATA;
        end;

       {Write Timeout Control}
       if (Command^.Data <> nil) or ((Command^.ResponseType and SDIO_RSP_BUSY) <> 0) then
        begin
         {$IFDEF MMC_DEBUG}
         if WIFI_LOG_ENABLED then WIFILogDebug(nil,'MMC Send Command SDHCI_TIMEOUT_CONTROL (Value=' + IntToHex(SDHCI_TIMEOUT_VALUE,8) + ')');
         {$ENDIF}
         SDHCIHostWriteByte(SDHCI,SDHCI_TIMEOUT_CONTROL,SDHCI_TIMEOUT_VALUE);
        end;

       {Check Data}
       if (command^.data = nil) then
        begin
         WIFILogDebug(nil, 'writing a standard command; status='+inttostr(command^.status));

         {Setup Transfer Mode}
         TransferMode:=SDHCIHostReadWord(SDHCI,SDHCI_TRANSFER_MODE);

         {Clear Auto CMD settings for non data CMDs}
         TransferMode:=TransferMode and not(SDHCI_TRNS_AUTO_CMD12 or SDHCI_TRNS_AUTO_CMD23);

         {Clear Block Count, Multi, Read and DMA for non data CMDs}
         TransferMode:=TransferMode and not(SDHCI_TRNS_BLK_CNT_EN or SDHCI_TRNS_MULTI or SDHCI_TRNS_READ or SDHCI_TRNS_DMA);

         {Write Argument}
         {$IFDEF MMC_DEBUG}
         if WIFI_LOG_ENABLED then WIFILogDebug(nil,'MMC Send Command SDHCI_ARGUMENT (Value=' + IntToHex(Command^.Argument,8) + ')');
         {$ENDIF}

         SDHCIHostWriteLong(SDHCI,SDHCI_ARGUMENT,Command^.Argument);

         {Write Transfer TransferMode}
         {$IFDEF MMC_DEBUG}
         if WIFI_LOG_ENABLED then WIFILogDebug(nil,'MMC Send Command SDHCI_TRANSFER_MODE (Value=' + IntToHex(TransferMode,8) + ')');
         {$ENDIF}

         SDHCIHostWriteWord(SDHCI,SDHCI_TRANSFER_MODE,TransferMode);
        end
       else
        begin
         {Setup Data}
         Command^.Data^.BlockOffset:=0;
         if (Command^.Data^.BlockCount = 0) then
            Command^.Data^.BlocksRemaining := 1
         else
           Command^.Data^.BlocksRemaining:=Command^.Data^.BlockCount;  // not sure if code expects there always to be a block count
         Command^.Data^.BytesTransfered:=0;

         WIFILogDebug(nil, 'blockcount='+inttostr(command^.data^.blockcount) + ' blocksize='+inttostr(command^.data^.blocksize));

         {Setup Transfer TransferMode}
         TransferMode := 0;
         if (Command^.Data^.BlockCount > 0) then
          begin
           WIFILogDebug(nil, 'enabling block transfer TransferMode');
           TransferMode:=SDHCI_TRNS_BLK_CNT_EN;
           TransferMode:=TransferMode or SDHCI_TRNS_MULTI;

          // TransferMode:=TransferMode or SDHCI_TRNS_AUTO_CMD12; //To Do //Testing (This works, need to sort out properly where it fits, plus SDHCI_TRNS_AUTO_CMD23)

           //To Do //SDHCI_TRNS_AUTO_CMD12 //SDHCI_TRNS_AUTO_CMD23 //SDHCI_ARGUMENT2 //See: sdhci_set_transfer_mode
                   //See 1.15 Block Count in the SD Host Controller Simplified Specifications
          end;
         if (txdata <> nil) then
         begin
            if ((txdata^.Flags and WIFI_DATA_READ) <> 0) then
              TransferMode := TransferMode or SDHCI_TRNS_READ;
         end
         else
         if (Command^.Data^.Flags and WIFI_DATA_READ) <> 0 then
          begin
           WIFILogDebug(nil, 'Add read flag to transfer mode');
           TransferMode:=TransferMode or SDHCI_TRNS_READ;
          end;

//         TransferMode := TransferMode or SDHCI_TRNS_R5;  //should be an R5 response for an SDIO device (for a cmd53 -- needs some changes so it works generically)
// by not including this we should expect an R1 response.

         {Setup DMA Address}
         //TransferMode |= SDHCI_TRNS_DMA;
         //Address:=
         //To Do

         {Setup Interrupts}
         SDHCI^.Interrupts:=SDHCI^.Interrupts or (SDHCI_INT_DATA_AVAIL or SDHCI_INT_SPACE_AVAIL or SDHCI_INT_DATA_END);
         SDHCIHostWriteLong(SDHCI,SDHCI_INT_ENABLE,SDHCI^.Interrupts);
         SDHCIHostWriteLong(SDHCI,SDHCI_SIGNAL_ENABLE,SDHCI^.Interrupts);
         //To Do //Different for DMA //Should we disable these again after the command ? //Yes, probably

         {Write DMA Address}
         //To Do
         //SDHCIHostWriteLong(SDHCI,SDHCI_DMA_ADDRESS,Address);

         {Write Block Size}
         if WIFI_LOG_ENABLED then WIFILogDebug(nil,'WIFI Send Command SDHCI_BLOCK_SIZE (Value=' + IntToStr(Command^.Data^.BlockSize) + ') makeblocksize='+inttohex(SDHCIMakeBlockSize(SDHCI_DEFAULT_BOUNDARY_ARG,Command^.Data^.BlockSize), 8));

//         SDHCIHostWriteWord(SDHCI,SDHCI_BLOCK_SIZE,SDHCIMakeBlockSize(SDHCI_DEFAULT_BOUNDARY_ARG,Command^.Data^.BlockSize));
         SDHCIHostWriteWord(SDHCI,SDHCI_BLOCK_SIZE,SDHCIMakeBlockSize(SDHCI_DEFAULT_BOUNDARY_ARG,Command^.Data^.BlockSize)); //Command^.Data^.BlockSize);
//         WIFILogDebug(nil, 'actually wrote 0x' + inttohex(command^.data^.blocksize, 8) + ' to block size register');

         {Write Block Count}
         if WIFI_LOG_ENABLED then WIFILogDebug(nil,'WIFI Send Command SDHCI_BLOCK_COUNT (Value=' + IntToStr(Command^.Data^.BlockCount) + ')');
         SDHCIHostWriteWord(SDHCI,SDHCI_BLOCK_COUNT,Command^.Data^.BlockCount);

         blksizecnt := SDHCIHostReadLong(SDHCI, SDHCI_BLOCK_SIZE);
         WIFILogDebug(nil, 'reading back blksizecnt to match circle=0x'+inttohex(blksizecnt, 8));

         {Write Argument}
         if WIFI_LOG_ENABLED then WIFILogDebug(nil,'WIFI Send Command SDHCI_ARGUMENT (Value=' + IntToHex(Command^.Argument,8) + ')');
         SDHCIHostWriteLong(SDHCI,SDHCI_ARGUMENT,Command^.Argument);

         {Write Transfer TransferMode}
         if WIFI_LOG_ENABLED then WIFILogDebug(nil,'WIFI Send Command SDHCI_TRANSFER_MODE (Value=' + IntToHex(TransferMode,8) + ')');
         SDHCIHostWriteWord(SDHCI,SDHCI_TRANSFER_MODE,TransferMode);
        end;


       {Setup Command}
       // this cast is safe as the data types are the same size and shape but it should
       // not be persisted. The only 'easy' solution is to use the mmc command for all.
       // but I don't like that as it is not an mmc command.
       SDHCI^.Command:=PMMCCommand(Command);

       // if there is txdata, it needs to be sent just after the command is sent.
       // we are going to force this shortly after here.
       if (txdata <> nil) then
       begin
        WIFILogDebug(nil, 'Txddat is not nil - prepare sdio record');
        SDIODataP := Command^.Data;
        Command^.Data := txdata;
       end;

       try
        {Write Command}

        WIFILogDebug(nil,'WIFI Send Command SDHCI_COMMAND cmd=' + inttostr(command^.command) + '  value written to cmd register=' + IntToHex(SDHCIMakeCommand(Command^.Command,Flags),8) + ') status='+inttostr(command^.status));

        if (dodumpregisters) and (command^.Command = SDIO_CMD_RW_EXTENDED) then
        begin
          dumpregisters(WIFI);
          dodumpregisters := false;
        end;

        SDHCIHostWriteWord(SDHCI,SDHCI_COMMAND,SDHCIMakeCommand(Command^.Command,Flags));

        // restore command data for the response?
//        Command^.Data := SDIODataP;

        {Wait for Completion}   // short timeout for a read command.
        if SDHCI^.Command^.Data = nil then // need to go back to test for data=nil
         begin
          {Wait for Signal with Timeout (100ms)}
          Status:=SemaphoreWaitEx(SDHCI^.Wait,500);  // increased during debug
          if Status <> ERROR_SUCCESS then
           begin
            if Status = ERROR_WAIT_TIMEOUT then
             begin
              WIFILogDebug(nil,'WIFI Send Command Response (short) Timeout');
              Command^.Status:=SDHCI_STATUS_TIMEOUT;
              Exit;
             end
            else
             begin
              WIFILogDebug(nil,'WIFI Send Command Response (short) Failure semaphorewaitexresult='+inttostr(status));
              Command^.Status:=SDHCI_STATUS_HARDWARE_ERROR;
              Exit;
             end;
           end
          else
          begin
           WIFILogDebug(nil, 'semaphore wait succeeded command=' + inttostr(command^.Command) + ' status=' + inttostr(command^.Status));
          end;
         end
        else
         begin
          {Wait for Signal with Timeout (5000ms)}
          WIFILogDebug(nil, 'wait for semaphore 5000');
          Status:=SemaphoreWaitEx(SDHCI^.Wait,5000);
          WIFILogDebug(nil, 'semaphore returned');
          if Status <> ERROR_SUCCESS then
           begin
            if Status = ERROR_WAIT_TIMEOUT then
             begin
              WIFILogError(nil,'WIFI Send Data Response Timeout');
              Command^.Status:=SDHCI_STATUS_TIMEOUT;
              Exit;
             end
            else
             begin
              WIFILogError(nil,'MMC Send Data Response Failure');
              Command^.Status:=SDHCI_STATUS_HARDWARE_ERROR;
              Exit;
             end;
           end
           else
            WIFILogDebug(nil, 'wait returned success');
         end;

       finally
        {Reset Command}
        SDHCI^.Command:=nil;
       end;
      finally
       {Check Status}
       if Command^.Status <> WIFI_STATUS_SUCCESS then //To Do //More see: sdhci_tasklet_finish //SDHCI_QUIRK_RESET_AFTER_REQUEST and SDHCI_QUIRK_CLOCK_BEFORE_RESET
        begin
         SDHCIHostReset(SDHCI,SDHCI_RESET_CMD);
         SDHCIHostReset(SDHCI,SDHCI_RESET_DATA);
        end;
      end;

     finally
      {Release the Lock}
      MutexUnlock(WIFI^.Lock);
     end;
    end;

   WIFILogDebug(nil,'WIFI Send Command completed: ' + MMCStatusToString(Command^.Status));
   if Command^.Status = WIFI_STATUS_SUCCESS then Result:=WIFI_STATUS_SUCCESS;
  end;

 //See: mmc_send_cmd in mmc.c
 //     sdhci_send_command in sdhci.c
 //See: bcm2835_mmc_send_command in \linux-rpi-3.18.y\drivers\mmc\host\bcm2835-mmc.c
 //     sdhci_send_command in \linux-rpi-3.18.y\drivers\mmc\host\sdhci.c
end;


function WIFIDeviceSendApplicationCommand(WIFI:PWIFIDevice;Command:PSDIOCommand):LongWord;
var
 Status:LongWord;
 SDHCI:PSDHCIHost;
 ApplicationCommand:TSDIOCommand;
begin
 {}
 Result:=SDHCI_STATUS_INVALID_PARAMETER;

 {Check MMC}
 if WIFI = nil then Exit;

 {$IFDEF MMC_DEBUG}
 if WIFI_LOG_ENABLED then WIFILogDebug(nil,'SD Send Application Command');
 {$ENDIF}

 {Get SDHCI}
 SDHCI:=PSDHCIHost(WIFI^.Device.DeviceData);
 if SDHCI = nil then Exit;

 {Setup Application Command}
 FillChar(ApplicationCommand,SizeOf(TSDIOCommand),0);
 ApplicationCommand.Command:=SDIO_CMD_APP_CMD;
 ApplicationCommand.Argument:=(WIFI^.RelativeCardAddress shl 16);
 ApplicationCommand.ResponseType:= SDIO_RSP_R1;
 ApplicationCommand.Data:=nil;

 {Send Application Command}
 Status:=WIFIDeviceSendCommand(WIFI,@ApplicationCommand);
 if Status <> WIFI_STATUS_SUCCESS then
  begin
   Result:=Status;
   Exit;
  end;

 {Check Response}
  if (ApplicationCommand.Response[0] and WIFI_RSP_R1_APP_CMD) = 0 then
   begin
    if WIFI_LOG_ENABLED then WifiLogError(nil,'SD Send Application Command Not Supported');
    Command^.Status:=WIFI_STATUS_UNSUPPORTED_REQUEST;
    Exit;
   end;

 {Send Command}
 Status:=WIFIDeviceSendCommand(WIFI,Command);
 if Status <> WIFI_STATUS_SUCCESS then
  begin
   Result:=Status;
   Exit;
  end;

 Result:=WIFI_STATUS_SUCCESS;

 //See: mmc_wait_for_app_cmd in \linux-rpi-3.18.y\drivers\mmc\core\sd_ops.c
end;


function WIFIDeviceCoreScan(WIFI : PWIFIDevice) : longint;
const
  corescansz = 512;
  CID_ID_MASK  =   $0000ffff;
  CID_REV_MASK  =  $000f0000;
  CID_REV_SHIFT  = 16;
  CID_TYPE_MASK  = $f0000000;
  CID_TYPE_SHIFT = 28;

var
 buf : array[0..511] of byte;
 i, coreid, corerev : integer;
 addr : longint;
 addressbytes : array[1..4] of byte;
 address : longword;
 str : string;
 chipidbuf : longword;
 chipid : word;
 chiprev : word;
 socitype : word;
begin
 wifiloginfo(nil, 'Starting core scan');

 Result := WIFI_STATUS_INVALID_PARAMETER;

 // set backplane window
 fillchar(buf, sizeof(buf), 0);

 Result := WIFIDeviceSetBackplaneWindow(WIFI, BAK_BASE_ADDR);

 // read 32 bits containing chip id and other info
 Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BACKPLANE_FUNCTION,0,  0, pbyte(@chipidbuf));
 if (Result <> WIFI_STATUS_SUCCESS) then
    wifilogerror(nil, 'failed to read the first byte of the chip id');

 Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BACKPLANE_FUNCTION,1,  0, pbyte(@chipidbuf)+1);
 Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BACKPLANE_FUNCTION,2,  0, pbyte(@chipidbuf)+2);
 Result:=SDIOWIFIDeviceReadWriteDirect(WIFI,sdioRead,BACKPLANE_FUNCTION,2,  0, pbyte(@chipidbuf)+3);

 chipid := chipidbuf  and CID_ID_MASK;
 chiprev := (chipidbuf and CID_REV_MASK) shr CID_REV_SHIFT;
 socitype := (chipidbuf and CID_TYPE_MASK) shr CID_TYPE_SHIFT;
 wifilogdebug(nil, 'chipid ' + inttohex(chipid,4) + ' chiprev ' + inttohex(chiprev, 4) + ' socitype ' + inttohex(socitype,4));

 // read pointer to core info structure.
 // 63*4 is yucky. Could do with a proper address definition for it.
 Result := SDIOWIFIDeviceReadWriteExtended(WIFI, sdioRead, BACKPLANE_FUNCTION, 63*4, true, @addressbytes[1], 0, 4, 1);
 address := plongint(@addressbytes[1])^;

 WIFILogdebug(nil, 'Core info pointer is read as ' + inttohex(address, 8));

 // we must get the top 15 bits from the address and set the bakplane window to it
 WIFIDeviceSetBackplaneWindow(WIFI, address);

 address := (address and $7fff) or $8000;

 try
 // read the core info from the device
  Result := SDIOWIFIDeviceReadWriteExtended(WIFI, sdioRead, BACKPLANE_FUNCTION, address, true, @buf[0], 8, 64, 2);
 if (Result <> WIFI_STATUS_SUCCESS) then
   wifilogerror(nil, 'Failed to read using extended call')
 else
   WIFILogDebug(nil, 'read block success ' + inttostr(i));

 // dump the block into the log so we can take a look at it during development
 // this code will be deleted later.
 str := '';
 for i := 1 to 512 do
 begin
   str := str + ' ' + inttohex(buf[i-1], 2);
   if i mod 20 = 0 then
   begin
     WIFILogDebug(nil, str);
     str := '';
   end;
 end;
 WIFILogDebug(nil, str);


 coreid := 0;
 corerev := 0;

 i := 0;

  while i < Corescansz do
  begin
     case buf[i] and $0f of
 	  $0F: begin
                 WIFILogDebug(nil, 'Reached end of descriptor');
                 break;
               end;
          $01:	// core info */
               begin
 		  if((buf[i+4] and $F) <> $01) then
 			  break;
 		  coreid := buf[i+1] or (buf[i+2] shl 8) and $FFF;
 		  i += 4;
 		  corerev := buf[i+3];
               end;
          $05:	// address */
               begin
 		  addr := (buf[i+1] shl 8) or (buf[i+2] shl 16) or (buf[i+3]<<24);
 		  addr := addr and (not $FFF);
  		  case coreid of
  		    $800:
                    begin
                       WIFI^.chipcommon := addr;
                    end;
                    ARMcm3,
  		    ARM7tdmi,
  		    ARMcr4:
                    begin
                       WIFI^.armcore := coreid;
                       if ((buf[i] and $c0) > 0) then
                       begin
                         if (WIFI^.armctl = 0) then
                           WIFI^.armctl := addr;
                       end
                       else
                       if (WIFI^.armregs = 0) then
                          WIFI^.armregs := addr;
                    end;

  		    $80E:
                    begin
                       if ((buf[i] and $c0) > 0) then
                         WIFI^.socramctl := addr
                       else
                       if (WIFI^.socramregs = 0) then
                         WIFI^.socramregs := addr;
                       WIFI^.socramrev := corerev;
                    end;

                    $829:
                    begin
                       if ((buf[i] and $c0) = 0) then
                         WIFI^.sdregs := addr;
                       WIFI^.sdiorev := corerev;
                    end;

                    $812:
                    begin
                       if ((buf[i] and $c0) > 0) then
                         WIFI^.dllctl := addr;
                    end;
                  end;
               end;
     end;
    i := i + 4;
  end;

  wifiloginfo(nil, 'Corescan completed.');
  WIFILogDebug(nil,'chipcommon=0x' + inttohex(WIFI^.chipcommon,8));
  WIFILogDebug(nil,'armcore=0x' + inttohex(WIFI^.armcore,8));
  WIFILogDebug(nil,'armctl=0x' + inttohex(WIFI^.armctl,8));
  WIFILogDebug(nil,'armregs=0x' + inttohex(WIFI^.armregs,8));
  WIFILogDebug(nil,'socramctl=0x' + inttohex(WIFI^.socramctl,8));
  WIFILogDebug(nil,'socramregs=0x' + inttohex(WIFI^.socramregs,8));
  WIFILogDebug(nil,'socramrev=0x' + inttohex(WIFI^.socramrev,8));
  WIFILogDebug(nil,'sdregs=0x' + inttohex(WIFI^.sdregs,8));
  WIFILogDebug(nil,'sdiorev=0x' + inttohex(WIFI^.sdiorev,8));
  WIFILogDebug(nil,'dllctl=0x' + inttohex(WIFI^.dllctl,8));

 except
   on e : exception do
     wifilogerror(nil, 'exception in corescan: ' + e.message);
 end;

end;

function cfgreadl(WIFI : PWIFIDevice; addr : longword; callerid:word=0) : longword;
var
  v : longword;
begin
  v := 0;
  Result := SDIOWIFIDeviceReadWriteExtended(WIFI, sdioRead, BACKPLANE_FUNCTION, (addr and $1ffff) or $8000, true, @v, 0, 4, 3);
  if (Result <> WIFI_STATUS_SUCCESS) then
    wifilogerror(nil, 'Failed to read config item 0x'+inttohex(addr, 8) + ' callerid='+inttostr(callerid) + ' result='+inttostr(Result));
  Result := v;
end;

procedure cfgwritel(WIFI : PWIFIDevice; addr : longword; v : longword);
var
  Result : longword;
begin
 Result := SDIOWIFIDeviceReadWriteExtended(WIFI, sdioWrite, BACKPLANE_FUNCTION, (addr and $1ffff) or $8000, true, @v, 0, 4, 4);
 if (Result <> WIFI_STATUS_SUCCESS) then
   wifilogerror(nil,'Failed to update config item 0x'+inttohex(addr, 8));
end;

procedure cfgw(WIFI : PWIFIDevice; offset : longword; value : byte);
var
  Result : longword;
begin
  Result := SDIOWIFIDeviceReadWriteDirect(WIFI, sdioWrite, BACKPLANE_FUNCTION, offset, value, nil);
  if (Result <> WIFI_STATUS_SUCCESS) then
    wifilogerror(nil, 'Failed to write config item 0x'+inttohex(offset, 8));
end;

function cfgr(WIFI : PWIFIDevice; offset : longword) : byte;
var
  Res : longword;
  value : byte;
begin
  Res := SDIOWIFIDeviceReadWriteDirect(WIFI, sdioRead, BACKPLANE_FUNCTION, offset, 0, @value);
  if (Res <> WIFI_STATUS_SUCCESS) then
    wifilogerror(nil, 'Failed to read config item 0x'+inttohex(offset, 8));

  Result := value;
end;

procedure sbdisable(WIFI : PWIFIDevice; regs : longword; pre : word; ioctl : word);
begin
 try
  WIFIDeviceSetBackplaneWindow(WIFI,  regs);

  if ((cfgreadl(WIFI, regs + Resetctrl) and 1) <> 0) then
  begin
    cfgwritel(WIFI, regs + Ioctrl, 3 or ioctl);
    cfgreadl(WIFI, regs + Ioctrl);
    exit;
  end;

  cfgwritel(WIFI, regs + Ioctrl, 3 or pre);
  cfgreadl(WIFI, regs + Ioctrl);
  cfgwritel(WIFI, regs + Resetctrl, 1);

  MicrosecondDelay(10);

  while((cfgreadl(WIFI, regs + Resetctrl) and 1) = 0) do
    begin
      MicrosecondDelay(10);
    end;

  cfgwritel(WIFI, regs + Ioctrl, 3 or ioctl);
  cfgreadl(WIFI, regs + Ioctrl);
 except
   on e : exception do
     wifilogerror(nil, 'exception in sbdisable 0x' + inttohex(longword(exceptaddr), 8));
 end;
end;

procedure sbmem(WIFI : PWIFIDevice; write : boolean; buf : pointer; len : longword; off : longword);
var
  n : longword;
  addr : longword;
  Res : longword;
begin
  n := (((off)+(Sbwsize)-1) div (Sbwsize) * (Sbwsize)) - off;
  if (n = 0) then
    n := Sbwsize;

  WIFILogDebug(nil, 'sbmem len='+inttostr(len) + ' n=' + inttostr(n) + ' offset=0x'+inttohex(off,8) + ' off&(sbwsize-1)=0x' + inttohex(off and (Sbwsize-1), 8));
  while (len > 0) do
  begin
    if (n > len) then
      n := len;

    WIFIDeviceSetBackplaneWindow(WIFI, off);
    addr := off and (sbwsize-1);

    if (len >= 4) then
      addr := addr or $8000;

    if (n < WIFI_BAK_BLK_BYTES) then
      Res := SDIOWIFIDeviceReadWriteExtended(WIFI, sdioWrite, BACKPLANE_FUNCTION, addr, true, buf, 0, n, 5)
    else
    begin
      Res := SDIOWIFIDeviceReadWriteExtended(WIFI, sdioWrite, BACKPLANE_FUNCTION, addr, true, buf, n div WIFI_BAK_BLK_BYTES, WIFI_BAK_BLK_BYTES, 6);
      n := (n div WIFI_BAK_BLK_BYTES) * WIFI_BAK_BLK_BYTES;
    end;

    if (Res <> WIFI_STATUS_SUCCESS) then
    begin
      WIFILogError(nil, 'Error transferring to/from backplane 0x' + inttohex(addr,8) + ' ' + inttostr(n) + 'bytes (write='+booltostr(write, true)+')');
    end;

    off += n;
    buf += n;
    len -= n;
    n := Sbwsize;
  end;
end;

procedure sbreset(WIFI : PWIFIDevice; regs : longword; pre : word; ioctl : word);

begin
 sbdisable(WIFI, regs, pre, ioctl);
 WIFIDeviceSetBackplaneWindow(WIFI, regs);
 WIFILogDebug(nil, 'sbreset entry regs 0x' + inttohex(regs, 8) + ' regs+ioctrl val 0x'
                   + inttohex(cfgreadl(WIFI, regs + IOCtrl), 8)
                   + ' regs+resetctrl val 0x ' + inttohex(cfgreadl(WIFI, regs + Resetctrl), 8));
  while ((cfgreadl(WIFI, regs + Resetctrl) and 1) <> 0) do
  begin
    cfgwritel(WIFI, regs + Resetctrl, 0);
    MicrosecondDelay(40);
  end;

  cfgwritel(WIFI, regs + Ioctrl, 1 or ioctl);
  cfgreadl(WIFI, regs + Ioctrl);

  WIFILogDebug(nil, 'sbreset exit regs+ioctrl val 0x' + inttohex(cfgreadl(WIFI, regs + IOCtrl), 8)
                    + ' regs+resetctrl val 0x ' + inttohex(cfgreadl(WIFI, regs + Resetctrl), 8));
end;

procedure WIFIDeviceRamScan(WIFI : PWIFIDevice);
var
 n, size : longword;
 r : longword;
 banks, i : longword;
begin
  if (WIFI^.armcore = ARMcr4) then
  begin
    r := WIFI^.armregs;
    wifilogdebug(nil, 'ramscan armcr4 0x' + inttohex(r, 8));
    WIFIDeviceSetBackplaneWindow(WIFI, r);
    r := (r and $7fff) or $8000;
    n := cfgreadl(WIFI, r + Cr4Cap);

    wifilogdebug(nil, 'cr4 banks 0x' + inttohex(n, 8));

    banks := ((n shr 4) and $F) + (n and $F);
    size := 0;

    wifilogdebug(nil, 'banks='+inttostr(banks));

    for i := 0 to banks - 1 do
    begin
       cfgwritel(WIFI, r + Cr4Bankidx, i);
       n := cfgreadl(WIFI, r + Cr4Bankinfo);
       wifilogdebug(nil, 'bank ' + inttostr(i) + ' reg 0x' + inttohex(n, 2) + ' size 0x' + inttohex(8192 * ((n and $3F) + 1), 8));
       size += 8192 * ((n and $3F) + 1);
    end;
    WIFI^.socramsize := size;
    WIFI^.rambase := $198000;
    WIFILogdebug(nil, 'Socram size=0x'+inttohex(size, 8) + ' rambase=0x'+inttohex(WIFI^.rambase, 8));
    exit;
  end;

  sbreset(WIFI, WIFI^.socramctl, 0, 0);
  r := WIFI^.socramregs;
  WIFIDeviceSetBackplaneWindow(WIFI, r);
  n := cfgreadl(WIFI, r + Coreinfo);

  wifilogdebug(nil ,'socramrev ' + inttostr(WIFI^.socramrev) + ' coreinfo 0x' + inttohex(n, 8));

  banks := (n>>4) and $F;
  size := 0;
  for i := 0 to banks-1 do
  begin
    cfgwritel(WIFI, r + Bankidx, i);
    n := cfgreadl(WIFI, r + Bankinfo);
    wifilogdebug(nil, 'bank ' + inttostr(i) + ' reg 0x' + inttohex(n, 2) + ' size 0x' + inttohex(8192 * ((n and $3F) + 1), 8));
    size += 8192 * ((n and $3F) + 1);
  end;
  WIFI^.socramsize := size;
  WIFI^.rambase := 0;
  if(WIFI^.chipid = 43430) then
  begin
    wifilogdebug(nil, 'updating bankidx values for 43430');
    cfgwritel(WIFI, r + Bankidx, 3);
    cfgwritel(WIFI, r + Bankpda, 0);
  end;

  WIFILogdebug(nil, 'Socram size=0x'+inttohex(size, 8) + ' rambase=0x'+inttohex(WIFI^.rambase, 8));

end;


(*
 * Condense config file contents (in buffer buf with length n)
 * to 'var=value\0' list for firmware:
 *	- remove comments (starting with '#') and blank lines
 *	- remove carriage returns
 *	- convert newlines to nulls
 *	- mark end with two nulls
 *	- pad with nulls to multiple of 4 bytes total length
 *)

function condense(buf : pchar; n : integer) : integer;
var
 p, ep, lp, op : pchar;
 c : char;
 skipping : boolean;
 i : integer;
begin

  Result := 0;
  skipping := false;      // true if in a comment
  ep := buf + n;          // end of input
  op := buf;              // end of output
  lp := buf;              // start of current output line

  p := buf;
  while (p < ep) do
  begin
    c := p^;

    case c of
      '#' : skipping := true;
      #0,
      #10 : begin
              skipping := false;
    	      if (op <> lp) then
              begin
                op^ := #0;
                op += 1;
                lp := op;
              end;
            end;
      #13: ; //do nothing (don't include in output)
    else
      if (not skipping) then
      begin
        op^ := c;
        op += 1;
      end;
    end;

    p += 1;
  end;

  if( not skipping) and (op <> lp) then
  begin
    op^ := #0;
    op+=1;
  end;

  op^ := #0;
  op+=1;

  // pad with nulls to multiple of 4 bytes length
  // note input has to be dword aligned to avoid a crash here.

  n := op - buf;
  while (n and 3 <> 0) do
  begin
    op^ := #0;
    op += 1;
    n += 1;
  end;
  Result := n;
end;

procedure put4(var p : byte4; v : longword);
begin
  p[1] := byte(v and $ff);
  p[2] := byte(v >> 8);
  p[3] := byte(v >> 16);
  p[4] := byte(v >> 24);
end;

procedure put4_2(p  : pbyte; v : longword);
begin
  p^ := byte(v and $ff);
  (p+1)^ := byte(v >> 8);
  (p+2)^ := byte(v >> 16);
  (p+3)^ := byte(v >> 24);
end;

procedure put2(p : pbyte; v : word);
begin
  p^ := v and $ff;
  (p+1)^ := (v shr 8) and $ff;
end;

function WIFIDeviceDownloadFirmware(WIFI : PWIFIDevice) : Longword;

var
 rambase : longword;
 FirmwareFile : file of byte;
 firmwarep : pbyte;
 comparebuf : pbyte;
 off : longword;
 fsize : longword;
 i : integer;
 lastramvalue : longword;
 chunksize : longword;
 bytesleft : longword;
 bytestransferred : longword;
 Found : boolean;
 ConfigFilename : string;
 FirmwareFilename : string;
 s : string;
 bytebuf : array[1..4] of byte;
 flag : word;
begin
 try
  Result := WIFI_STATUS_INVALID_PARAMETER;

  // zero out an address of some sort which is at the top of the ram?
  lastramvalue := 0;
  WIFIDeviceSetBackplaneWindow(WIFI, WIFI^.rambase + WIFI^.socramsize - 4);
  SDIOWIFIDeviceReadWriteExtended(WIFI, sdioWrite, BACKPLANE_FUNCTION, (WIFI^.rambase + WIFI^.socramsize - 4) and $7fff{ or $8000}, true, @lastramvalue, 0, 4, 7);

  WIFILogInfo(nil, 'Starting firmware load...');

  // locate firmware detils based on chip id and revision

  Found := false;

  for i := 1 to FIRWMARE_OPTIONS_COUNT do
  begin
    if (firmware[i].chipid = WIFI^.chipid) and (firmware[i].chipidrev = WIFI^.chipidrev) then
    begin
      FirmwareFilename := FIRMWARE_FILENAME_ROOT + firmware[i].firmwarefilename;
      ConfigFilename := FIRMWARE_FILENAME_ROOT + firmware[i].configfilename;
      Found := true;
      break;
    end;
  end;

  if (not Found) then
  begin
    WIFILogError(nil, 'Unable to find a suitable firmware file to load for chip id 0x' + inttohex(WIFI^.chipid, 4) + ' revision 0x' + inttohex(WIFI^.chipidrev, 4));
    exit;
  end;

  WIFILogInfo(nil, 'Using ' + FirmwareFilename + ' for firmware.');

  // open file and read entire block into memory. Perhaps ought to do this in
  // chunks really? If we do, then the verify stuff needs to be done a chunk
  // at a time as well.

  assignfile(FirmwareFile, FirmwareFilename);
  reset(FirmwareFile);
  fsize := filesize(FirmwareFile);
  getmem(firmwarep, fsize);
  blockread(FirmwareFile, firmwarep^, fsize);
  closefile(FirmwareFile);

  // transfer firmware over the bus to the chip.
  // first, grab the reset vector from the first 4 bytes of the firmware.
  // Not needed on a Pi Zero as the firmware loads at addres 0 by default - needs updating to suit.

  move(firmwarep^, WIFI^.resetvec, 4);
  wifilogdebug(nil, 'Reset vector of 0x' + inttohex(WIFI^.resetvec, 8) + ' copied out of firmware');

  off := 0;
  if (fsize > FIRMWARE_CHUNK_SIZE) then
    chunksize := FIRMWARE_CHUNK_SIZE
  else
    chunksize := fsize;

  // dword align the buffer size.
  if (fsize mod 4 <> 0) then
    fsize := ((fsize div 4) + 1) * 4;

  getmem(comparebuf, fsize);

  wifilogdebug(nil, 'Bytes to transfer: ' + inttostr(fsize));
  bytestransferred := 0;
  dodumpregisters := false;

  while bytestransferred < fsize do
  begin
    sbmem(WIFI, true, firmwarep+off, chunksize, WIFI^.rambase + off);
    bytestransferred := bytestransferred + chunksize;

    off += chunksize;
    bytesleft := fsize - bytestransferred;
    if (bytesleft < chunksize) then
      chunksize := bytesleft;
  end;


  off := 0;
  if (fsize > FIRMWARE_CHUNK_SIZE) then
    chunksize := FIRMWARE_CHUNK_SIZE
  else
    chunksize := fsize;

 (*
 We don't need this comparison to always run
 This verify code needs updating to match the upload code now
 anyway. Do that later and move to an ifdef or global boolean.


  wifiloginfo(nil, 'bytes to read are ' + inttostr(fsize));
  bytestransferred := 0;
  while bytestransferred < fsize do
  begin

    sbmem(WIFI, false, comparebuf+off, chunksize, WIFI^.rambase + off);
    bytestransferred := bytestransferred + chunksize;
     wifiloginfo(nil, 'bytes transferred = ' + inttostr(bytestransferred) + ' bytes left = ' +inttostr(fsize-bytestransferred));

    if (bytestransferred < fsize) then
    begin
      off += FIRMWARE_CHUNK_SIZE;
      if (off + chunksize > fsize) then
        chunksize := fsize - off;
    end;
  end;


  WIFILogDebug(nil, 'block comparison started');
  for i := 0 to fsize - 1 do
    if (pbyte(firmwarep+i)^ <> pbyte(comparebuf+i)^) then
    begin
      wifiloginfo(nil, 'compare failed at byte ' + inttostr(i));
      break;
    end;
  wifiloginfo(nil, 'block comparison completed');

  freemem(comparebuf);
  *)

  freemem(firmwarep);


  // now we need to upload the configuration to ram

  AssignFile(FirmwareFile, ConfigFilename);
  Reset(FirmwareFile);
  FSize := FileSize(FirmwareFile);

  WIFILogdebug(nil, 'Size of firmware config file is ' + inttostr(fsize) + ' bytes');

  // dword align to be sure
  if (fsize mod 4 <> 0) then
    fsize := ((fsize div 4) + 1) * 4;

  GetMem(firmwarep, fsize);
  BlockRead(FirmwareFile, FirmwareP^, FileSize(FirmwareFile));



  fsize := Condense(PChar(FirmwareP), Filesize(FirmwareFile)); // note we deliberately *don't* use fsize here!

  // Although what we've done here is correct, I noticed that ether4330.c only
  // reads the first 2048 bytes of the config which it then condenses, resulting
  // in a config string of 1720 bytes which misses off the last few items and
  // truncates on of the assigned values.
  // This just looks like a simple bug - on a Pi3B the file is about 2074 bytes
  // and perhaps in the past it was smaller so would fit in the 2048 byte read.

  off := WIFI^.rambase + WIFI^.socramsize - fsize - 4;
  WIFILogDebug(nil, 'Tansferring config file to socram at offset 0x' + inttohex(off, 8));
  bytestransferred := 0;

  if (fsize > FIRMWARE_CHUNK_SIZE) then
    chunksize := FIRMWARE_CHUNK_SIZE
  else
    chunksize := fsize;

  while bytestransferred < fsize do
  begin
    sbmem(WIFI, true, firmwarep+bytestransferred, chunksize, off);
    bytestransferred := bytestransferred + chunksize;

    off += chunksize;
    bytesleft := fsize - bytestransferred;
    if (bytesleft < chunksize) then
      chunksize := bytesleft;
  end;

  Freemem(firmwarep);

  WIFILogInfo(nil, 'Finished transferring config file to socram');

  // I believe this is some sort of checksum
  fsize := fsize div 4;
  fsize := (fsize and $ffff) or ((not fsize) << 16);

  // write checksum thingy to ram.

  put4(bytebuf, fsize);
  sbmem(WIFI, true, @bytebuf[1], 4, WIFI^.rambase + WIFI^.socramsize - 4);

  // I think this brings the arm core back up after writing the firmware.
  if (WIFI^.armcore = ARMcr4) then
  begin
     WIFIDeviceSetBackplaneWindow(WIFI, WIFI^.sdregs);
     cfgwritel(WIFI, WIFI^.sdregs + IntStatus, $ffffffff);
     // write reset vector to bottom of RAM
     if (WIFI^.resetvec <> 0) then
     begin
       wifilogdebug(nil, 'Firmware upload: Writing reset vector to address 0');
       sbmem(WIFI, true, @WIFI^.resetvec, sizeof(WIFI^.resetvec), 0);
     end;

     // reactivate the core.
     sbreset(WIFI, WIFI^.armctl, Cr4Cpuhalt, 0);
  end
  else
     sbreset(WIFI, WIFI^.armctl, 0, 0);
 except
   on e : exception do
     wifilogerror(nil, 'exception : ' + e.message + ' at address ' + inttohex(longword(exceptaddr),8));
 end;
end;

procedure sbenable(WIFI : PWIFIDevice);
var
  i : integer;
  iobits : byte;
  mbox : longword;
  ints : longword;
begin
  WIFIDeviceSetBackplaneWindow(WIFI, BAK_BASE_ADDR);
  WIFILogInfo(nil, 'Enabling high throughput clock...');
  cfgw(WIFI, BAK_CHIP_CLOCK_CSR_REG, 0);
  sleep(1);
  cfgw(WIFI, BAK_CHIP_CLOCK_CSR_REG, ReqHT);

  // wait for HT clock to become available. 100ms timeout approx
  i := 0;
  while ((cfgr(WIFI, BAK_CHIP_CLOCK_CSR_REG) and HTavail) = 0) do
  begin
    i += 1;
    if (i = 100) then
    begin
      WIFILogError(nil, 'Could not enable HT clock; csr=' + inttohex(cfgr(WIFI, BAK_CHIP_CLOCK_CSR_REG), 8));
      exit;
    end;

    Sleep(1);
  end;

  cfgw(WIFI, BAK_CHIP_CLOCK_CSR_REG, cfgr(WIFI, BAK_CHIP_CLOCK_CSR_REG) or ForceHT);
  sleep(10);

  WIFILogDebug(nil, 'After request for HT clock, CSR_REG=0x' + inttohex(cfgr(WIFI, BAK_CHIP_CLOCK_CSR_REG), 4));

  WIFIDeviceSetBackplaneWindow(WIFI, WIFI^.sdregs);

  cfgwritel(WIFI, WIFI^.sdregs + Sbmboxdata, 4 shl 16);   // set protocol version
  cfgwritel(WIFI, WIFI^.sdregs + Intmask, FrameInt or MailboxInt or Fcchange);

  // enable function 2
  SDIOWIFIDeviceReadWriteDirect(WIFI, sdioRead, BUS_FUNCTION, SDIO_CCCR_IOEx, 0, @iobits);
  SDIOWIFIDeviceReadWriteDirect(WIFI, sdioWrite, BUS_FUNCTION, SDIO_CCCR_IOEx, iobits or SDIO_FUNC_ENABLE_2, nil);

  // now wait for function 2 to be ready
  i := 0;
  iobits := 0;
  while ((iobits and SDIO_FUNC_ENABLE_2) = 0) do
  begin
    i += 1;
    if (i = 10) then
    begin
      WIFILogError(nil, 'Could not enable SDIO function 2; iobits=0x'+inttohex(iobits, 8));
      exit;
    end;

    SDIOWIFIDeviceReadWriteDirect(WIFI, sdioRead, BUS_FUNCTION, SDIO_CCCR_IORx, 0, @iobits);

    Sleep(100);
  end;

  WIFILogInfo(nil, 'Radio function (f2) successfully enabled');

  // enable interrupts.
  SDIOWIFIDeviceReadWriteDirect(WIFI,sdioWrite, BUS_FUNCTION, SDIO_CCCR_IENx, (INTR_CTL_MASTER_EN or INTR_CTL_FUNC1_EN or INTR_CTL_FUNC2_EN), nil );

  ints := 0;
  while (ints = 0) do
  begin
    ints := cfgreadl(WIFI, WIFI^.sdregs + Intstatus);
    cfgwritel(WIFI, WIFI^.sdregs + Intstatus, ints);

    if ((ints and mailboxint) > 0) then
    begin
      mbox := cfgreadl(WIFI, WIFI^.sdregs + Hostmboxdata);
      cfgwritel(WIFI, WIFI^.sdregs + Sbmbox, 2);	//ack
      if ((mbox and $8) = $8) then
         WIFILogInfo(nil, 'The Broadcom firmware reports it is ready!')
      else
        WIFILogError(nil, 'The firmware is not ready! mbox=0x'+inttohex(mbox, 8));
    end
    else
      WIFILogError(nil, 'Mailbox interrupt was not set as expected ints=0x'+inttohex(ints, 8));
  end;

  // It seems like we need to execute a read first to kick things off. If we don't do this the first
  // IOCTL command response will be an empty one rather than the one for the IOCTL we sent.
  if (SDIOWIFIDeviceReadWriteExtended(WIFI, sdioRead, WLAN_FUNCTION, BAK_BASE_ADDR and $1ffff, false, @ioctl_rxmsg, 0, 64,8) <> WIFI_STATUS_SUCCESS) then
     wifilogdebug(nil, 'There seems to be nothing to read from function 2')
  else
    wifilogdebug(nil, 'Successfully read function 2 first empty response.');


  WIFILogInfo(nil, 'WIFI Device Enabled');
end;




function WirelessIOCTLCommand(WIFI : PWIFIDevice; cmd : integer;
                                   InputP : Pointer;
                                   InputLen : Longword;
                                   write : boolean; ResponseDataP : Pointer;
                                   ResponseDataLen : integer) : longword;

var
  msgp : PIOCTL_MSG = @ioctl_txmsg;
  responseP  : PIOCTL_MSG;
  cmdp : IOCTL_CMDP;
  TransmitDataLen : longword;
  HeaderLen : longword;
  TransmitLen : longword;
  Res : longword;
  i : integer;
  ints : longword;
  bytesleft : longword;
  bufferp : pbyte;
  finished : boolean = false;
  databytesreceived : word;
  eventrecordp : pwhd_event;
  s : string;
  temp : longword;
  WorkerRequestP : PWIFIRequestItem;

begin
  if txglom then
    cmdp := @(msgp^.glom_cmd.cmd)
  else
    cmdp := @(msgp^.cmd);

  WIFILogDebug(nil, 'wirelessioctlcmd write='+booltostr(write, true)
                   + ' cmd='+inttostr(cmd)
                   + ' InputLen='+inttostr(InputLen)
                   + ' datalen='+inttostr(responsedatalen));

  if (write) then
    TransmitDataLen := InputLen + ResponseDataLen
  else
    TransmitDataLen := max(InputLen, ResponseDataLen);

  // works out header length by subtracting addresses
  // this might look wrong but cmdp is a pointer to msgp's cmd and msgp is
  // a pointer to ioctl_txmsg. therefore the address are from the same instance.
  HeaderLen := @cmdp^.data - @ioctl_txmsg;
  TransmitLen := ((HeaderLen + TransmitDataLen + 3) div 4) * 4;

    // Prepare IOCTL command
  fillchar(msgp^, sizeof(IOCTL_MSG), 0);

  msgp^.len := HeaderLen + TransmitDataLen;
  msgp^.notlen := not msgp^.len;

  if (txglom) then
  begin
    msgp^.glom_cmd.glom_hdr.len := HeaderLen + TransmitDataLen - 4;
    msgp^.glom_cmd.glom_hdr.flags := 1;
  end;

  cmdp^.seq := txseq;
  if (txseq < 255) then
    txseq += 1
  else
    txseq := 0;

  if (txglom) then
    cmdp^.hdrlen := 20
  else
    cmdp^.hdrlen := 12;

  cmdp^.cmd := cmd;
  cmdp^.outlen := TransmitDataLen;

  // request id is a word, so need to stay within limits.
  if (ioctl_reqid > $fffe) then
    ioctl_reqid := 1
  else
    ioctl_reqid := ioctl_reqid + 1;

  if (write) then
    cmdp^.flags := (ioctl_reqid << 16) or 2
  else
    cmdp^.flags := (ioctl_reqid << 16);

  if (InputLen > 0) then
  begin
    move(InputP^, cmdp^.data[0], InputLen);
  end;

  if (write) then
    move(ResponseDataP^, PByte(@(cmdp^.data[0])+InputLen)^, ResponseDataLen);

  // Signal to the worker thread that we need a response for this request.
  WorkerRequestP := WIFIWorkerThread.AddRequest(ioctl_reqid, [], nil);

  // Send IOCTL command.
  // Is it safe to submit multiple ioctl commands and then see the events come through
  // out of order? I think so but needs testing and investigating.
  // requests are safe because the sdio read write functions have a spinlock.

  wifilogdebug(nil, 'sending ' + inttostr(TransmitLen) + ' bytes to the wifi device');
  Res := SDIOWIFIDeviceReadWriteExtended(WIFI, sdioWrite, WLAN_FUNCTION, BAK_BASE_ADDR and $1FFFF{ SB_32BIT_WIN}, false, msgp, 0, TransmitLen, 9);

  // wait for the worker thread to process the response.
  SemaphoreWait(WorkerRequestP^.Signal);

  // use old variable for now so copy paste from old code works still
  ResponseP := WorkerRequestP^.MsgP;
  if (ResponseP = nil) then
  begin
    wifilogerror(nil, 'response is nil!!!!!');
    exit;
  end;

  // Now we have the response we can validate it.
  if ((responseP^.cmd.chan and $f) <> 0) then
    WIFILogError(nil, 'IOCTL response received for a non-zero channel');

  if (((ResponseP^.cmd.flags >> 16) and $ffff) <> WorkerRequestP^.RequestID) then
    WIFILogError(nil, 'IOCTL response received for a different request id. We got one for '
                      + inttostr(responsep^.cmd.flags >> 16)
                      + ' whereas our request was for '
                      + inttostr(workerrequestp^.RequestID));

  // in cases where the response is smaller than the command parameters we have to move less data.
  // need to verify this as I had some weird if statement in there before.
  move(ResponseP^.cmd.Data[0], ResponseDataP^, ResponseDataLen);

  WIFIWorkerThread.DoneWithRequest(WorkerRequestP);
end;

procedure WirelessGetVar(WIFI : PWIFIDevice; varname : string; ValueP : PByte; len : integer);
begin
  // getvar name must have a null on the end of it.
  varname := varname + #0;

  WirelessIOCTLCommand(WIFI, WLC_GET_VAR, @varname[1], length(varname), false, ValueP, len);
end;

procedure WirelessSetVar(WIFI : PWIFIDevice; varname : string; InputValueP : PByte; Inputlen : integer);
begin
  varname := varname + #0;
  WirelessIOCTLCommand(WIFI, WLC_SET_VAR, @varname[1], length(varname), true, InputValueP, Inputlen);
end;

procedure WirelessSetInt(WIFI : PWIFIDevice; varname : string; Value : longword);
begin
  WirelessSetVar(WIFI, varname, @Value, 4);
end;

procedure WirelessCommandInt(WIFI : PWIFIDevice; wlccmd : longword; Value : longword);
var
  response : byte4;
begin
  WirelessIOCTLCommand(WIFI, wlccmd, @Value, 4, true, @response[1], 4);
end;

procedure WIFIDeviceUploadRegulatoryFile(WIFI : PWIFIDevice);
const
  Reguhdr = 2+2+4+4;
  Regusz = 400;
  Regutyp = 2;
  Flagclm = 1 shl 12;
  Firstpkt = 1 shl 1;
  Lastpkt = 1 shl 2;

var
 FirmwareFile : file of byte;
 firmwarep : pbyte;
 off : longword;
 fsize : longword;
 i : integer;
 chunksize : longword;
 Found : boolean;
 RegulatoryFilename : string;
 s : string;
 flag : word;

begin
  // locate regulatory detils based on chip id and revision

  WIFILogInfo(nil, 'Starting to upload regulatory file');
  Found := false;

  for i := 1 to FIRWMARE_OPTIONS_COUNT do
  begin
    if (firmware[i].chipid = WIFI^.chipid) and (firmware[i].chipidrev = WIFI^.chipidrev) then
    begin
      RegulatoryFilename := FIRMWARE_FILENAME_ROOT + firmware[i].regufilename;
      Found := true;
      break;
    end;
  end;

  if (not Found) then
  begin
    WIFILogError(nil, 'Unable to find a suitable firmware file to load for chip id 0x' + inttohex(WIFI^.chipid, 4) + ' revision 0x' + inttohex(WIFI^.chipidrev, 4));
    exit;
  end;

  WIFILogInfo(nil, 'Using ' + RegulatoryFilename + ' for regulatory file.');

  // now regulatory file if there is one.

  AssignFile(FirmwareFile, RegulatoryFilename);
  Reset(FirmwareFile);
  FSize := FileSize(FirmwareFile);

  WIFILogInfo(nil, 'Size of regulatory file is ' + inttostr(fsize) + ' bytes');

  // add in header sizes
(*  fsize := fsize + Reguhdr + 1;

  // dword align to be sure
  if (fsize mod 4 <> 0) then
    fsize := ((fsize div 4) + 1) * 4;*)

  GetMem(firmwarep, Reguhdr+Regusz+1);

  put2(firmwarep+2, Regutyp);
  put2(firmwarep+8, 0);
  off := 0;
  flag := Flagclm or Firstpkt;

  while ((flag and Lastpkt) = 0) do
  begin
    // read a block of data from the file
    BlockRead(FirmwareFile, (firmwarep+Reguhdr)^, Regusz, chunksize);
    if (chunksize <= 0) then
      break;

    if (chunksize <> Regusz) then
    begin
      // fill out end of the block with zeroes.
      while ((chunksize and 7) > 0) do
      begin
        (firmwarep+Reguhdr+chunksize)^ := 0;
        chunksize += 1;
      end;
      flag := flag or Lastpkt;
    end;

    put2(firmwarep+0, flag);
    put4_2(firmwarep+4, chunksize);
    WirelessSetVar(WIFI, 'clmload', firmwarep, Reguhdr + chunksize);
    off += chunksize;
    flag := flag and (not Firstpkt);
  end;

  freemem(firmwarep);

  WIFILogInfo(nil, 'Finished transferring regulatory file');
end;


function whd_tlv_find_tlv8(message : pbyte; message_length : longword; atype : byte) : pwhd_tlv8_data;
var
  current_tlv_type : byte;
  current_tlv_length : byte;
begin
  // scans list of TLV's for the one with tge specified atype.
  // and returns a pointer to it.

  Result := nil;

  while (message_length <> 0) do
  begin
    current_tlv_type := message^;
    current_tlv_length := pword(message+1)^ + 2;

    // Check if we've overrun the buffer
    if (current_tlv_length > message_length) then
      Exit;

    // Check if we've found the type we are looking for
    if (current_tlv_type = atype) then
    begin
      Result := pwhd_tlv8_data(message);
      exit;
    end;

    // Skip current TLV
    message += current_tlv_length;
    message_length -= current_tlv_length;
  end;
end;

procedure CheckSecurity(WIFI : PWIFIDevice; scanresultp : pwl_escan_result);
var
  ie_offset : word;
  cp : pwhd_tlv8_header;
  len : longword;
  bssinfoP : pwl_bss_info;
  bssinfolength : longword;
  rsnie : prsn_ie_fixed_portion;
begin
 // Determine the network security of the scan result
 // this procedure is sort of experimental at the moment.
 // we are going to need to build up some internal structures like
 // the cypress driver does in the end (I suspect)


  bssinfoP := @scanresultp^.bss_info[1];
  ie_offset := bssinfoP^.ie_offset;
  cp := pwhd_tlv8_header(pbyte(bssinfop) + ie_offset );
  len := bssinfop^.ie_length;
  bssinfolength := bssinfop^.length;

  wifiloginfo(nil, 'checksecurity ieoffset='+inttostr(ie_offset) + ' len='+inttostr(len) + ' bssinfolength='+inttostr(bssinfolength));

// record->ie_ptr = (uint8_t *)cp;
// record->ie_len = len;

  // Validate the length of the IE section
  if ((ie_offset > bssinfolength) or (len > bssinfolength - ie_offset) ) then
  begin
    wifilogerror(nil, 'Invalid IE length');
    exit;
  end;

  // Find an RSN IE (Robust-Security-Network Information-Element)
  rsnie := prsn_ie_fixed_portion(whd_tlv_find_tlv8(pbyte(cp), len, DOT11_IE_ID_RSN));
(*
  // Find a WPA IE
  if (rsnie == NULL)
  {
     whd_tlv8_header_t *parse = cp;
     uint32_t parse_len = len;
     while ( (wpaie =
                  (wpa_ie_fixed_portion_t * )whd_parse_tlvs(parse, parse_len, DOT11_IE_ID_VENDOR_SPECIFIC) ) != 0 )
     {
         if (whd_is_wpa_ie( (vendor_specific_ie_header_t * )wpaie, &parse, &parse_len ) != WHD_FALSE)
         {
             break;
         }
     }
 }

 temp16 = WHD_READ_16(&bss_info->capability);

 /* Check if AP is configured for RSN */
 if ( (rsnie != NULL) &&
      (rsnie->tlv_header.length >= RSN_IE_MINIMUM_LENGTH + rsnie->pairwise_suite_count * sizeof(uint32_t) ) )
 {
     uint16_t a;
     uint32_t group_key_suite;
     akm_suite_portion_t *akm_suites;
     DISABLE_COMPILER_WARNING(diag_suppress = Pa039)
     akm_suites = (akm_suite_portion_t * )&(rsnie->pairwise_suite_list[rsnie->pairwise_suite_count]);
     ENABLE_COMPILER_WARNING(diag_suppress = Pa039)
     for (a = 0; a < akm_suites->akm_suite_count; ++a)
     {
         uint32_t akm_suite_list_item = ntoh32(akm_suites->akm_suite_list[a]) & 0xFF;
         if (akm_suite_list_item == (uint32_t)WHD_AKM_PSK)
         {
             record->security |= WPA2_SECURITY;
         }
         if (akm_suite_list_item == (uint32_t)WHD_AKM_SAE_SHA256)
         {
             record->security |= WPA3_SECURITY;
         }
         if (akm_suite_list_item == (uint32_t)WHD_AKM_8021X)
         {
             record->security |= WPA2_SECURITY;
             record->security |= ENTERPRISE_ENABLED;
         }
         if (akm_suite_list_item == (uint32_t)WHD_AKM_FT_8021X)
         {
             record->security |= WPA2_SECURITY;
             record->security |= FBT_ENABLED;
             record->security |= ENTERPRISE_ENABLED;
         }
         if (akm_suite_list_item == (uint32_t)WHD_AKM_FT_PSK)
         {
             record->security |= WPA2_SECURITY;
             record->security |= FBT_ENABLED;
         }
     }

     group_key_suite = ntoh32(rsnie->group_key_suite) & 0xFF;
     /* Check the RSN contents to see if there are any references to TKIP cipher (2) in the group key or pairwise keys, */
     /* If so it must be mixed mode. */
     if (group_key_suite == (uint32_t)WHD_CIPHER_TKIP)
     {
         record->security |= TKIP_ENABLED;
     }
     if (group_key_suite == (uint32_t)WHD_CIPHER_CCMP_128)
     {
         record->security |= AES_ENABLED;
     }

     for (a = 0; a < rsnie->pairwise_suite_count; ++a)
     {
         uint32_t pairwise_suite_list_item = ntoh32(rsnie->pairwise_suite_list[a]) & 0xFF;
         if (pairwise_suite_list_item == (uint32_t)WHD_CIPHER_TKIP)
         {
             record->security |= TKIP_ENABLED;
         }

         if (pairwise_suite_list_item == (uint32_t)WHD_CIPHER_CCMP_128)
         {
             record->security |= AES_ENABLED;
         }
     }
 }
 /* Check if AP is configured for WPA */
 else if ( (wpaie != NULL) &&
           (wpaie->vendor_specific_header.tlv_header.length >=
            WPA_IE_MINIMUM_LENGTH + wpaie->unicast_suite_count * sizeof(uint32_t) ) )
 {
     uint16_t a;
     uint32_t group_key_suite;
     akm_suite_portion_t *akm_suites;

     record->security = (whd_security_t)WPA_SECURITY;
     group_key_suite = ntoh32(wpaie->multicast_suite) & 0xFF;
     if (group_key_suite == (uint32_t)WHD_CIPHER_TKIP)
     {
         record->security |= TKIP_ENABLED;
     }
     if (group_key_suite == (uint32_t)WHD_CIPHER_CCMP_128)
     {
         record->security |= AES_ENABLED;
     }

     akm_suites = (akm_suite_portion_t * )&(wpaie->unicast_suite_list[wpaie->unicast_suite_count]);
     for (a = 0; a < akm_suites->akm_suite_count; ++a)
     {
         uint32_t akm_suite_list_item = ntoh32(akm_suites->akm_suite_list[a]) & 0xFF;
         if (akm_suite_list_item == (uint32_t)WHD_AKM_8021X)
         {
             record->security |= ENTERPRISE_ENABLED;
         }
     }

     for (a = 0; a < wpaie->unicast_suite_count; ++a)
     {
         if (wpaie->unicast_suite_list[a][3] == (uint32_t)WHD_CIPHER_CCMP_128)
         {
             record->security |= AES_ENABLED;
         }
     }
 }
*)
end;

procedure WirelessScanCallback(Event : TWIFIEvent; EventRecordP : pwhd_event; RequestItemP : PWIFIRequestItem);
var
  ScanResultP : pwl_escan_result;
  ssidstr, s : string;
begin
  if (Event = WLC_E_ESCAN_RESULT) then
  begin
    scanresultp := pwl_escan_result(pbyte(@eventrecordp^.whd_event + sizeof(whd_event_msg)));
    ssidstr := buftostr(@scanresultp^.bss_info[1].SSID[0], scanresultp^.bss_info[1].SSID_len, true);
    if (ssidstr = '') then
      ssidstr := '<hidden>';

    s := 'SSID='+ssidstr
                  + ' event status=' + inttostr(eventrecordp^.whd_event.status)
                  + ' buflen = '+inttostr(scanresultp^.buflen)
                  + ' channel = ' +inttostr(scanresultp^.bss_info[1].chanspec and $ff)
                  + ' MAC = ' +inttohex(scanresultp^.bss_info[1].BSSID.octet[0], 2) + ':'
                  + inttohex(scanresultp^.bss_info[1].BSSID.octet[1], 2) + ':'
                  + inttohex(scanresultp^.bss_info[1].BSSID.octet[2], 2) + ':'
                  + inttohex(scanresultp^.bss_info[1].BSSID.octet[3], 2) + ':'
                  + inttohex(scanresultp^.bss_info[1].BSSID.octet[4], 2) + ':'
                  + inttohex(scanresultp^.bss_info[1].BSSID.octet[5], 2);
    if (eventrecordp^.whd_event.status = 8) then
      s := s + ' Partial scan result';
    WIFILogInfo(nil, s);
  end
  else
    WIFILogError(nil, 'what the fuck is that?');

end;

procedure WirelessScan(WIFI : PWIFIDevice);

const
  SCAN_PARAMS_LEN = 4+2+2+4+32+6+1+1+4*4+2+2+14*2+32+4;
  oldscanparams : array[0..SCAN_PARAMS_LEN-1] of byte =
    (
      1,0,0,0,
      1,0,
      $34,$12,
      0,0,0,0,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
      $ff,$ff,$ff,$ff,$ff,$ff,
      2,
      0,
      $ff,$ff,$ff,$ff,
      $ff,$ff,$ff,$ff,
      $00,$00,$10,$00,//$ff,$ff,$ff,$ff,
      $ff,$ff,$ff,$ff,
      14,0,
      1,0,
      $01,$2b,$02,$2b,$03,$2b,$04,$2b,$05,$2e,$06,$2e,$07,$2e,
      $08,$2b,$09,$2b,$0a,$2b,$0b,$2b,$0c,$2b,$0d,$2b,$0e,$2b,
      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0  // I had to add these four zeros.
  );

var
  scanparams : wl_escan_params;
  eventmask : array[0..WL_EVENTING_MASK_LEN] of byte;
  i : integer;
  RequestItemP : PWIFIRequestItem;

  procedure DisableEvent(id : integer);
  begin
     EventMask[id div 8] := EventMask[id div 8] and (not (1 << (id mod 8)));
  end;


begin
  // scan for wifi networks

  // perhaps implement a callback eventually, so that the caller can see the
  // networks being found.

  // passive scan - listens for beacons only.

  WIFILogInfo(nil, 'Starting wireless network scan');

  // set up the event mask
  fillchar(eventmask, sizeof(eventmask), 255);           // turn everything on
  DisableEvent(40);	// E_RADIO
  DisableEvent(44);	// E_PROBREQ_MSG
  DisableEvent(54);	// E_IF
  DisableEvent(71);	// E_PROBRESP_MSG
  DisableEvent(20);	// E_TXFAIL
  DisableEvent(124);	//?

  WirelessSetVar(WIFI, 'event_msgs', @eventmask, sizeof(eventmask));

  WirelessCommandInt(WIFI, $b9, $28); // scan channel time
  WirelessCommandInt(WIFI, $bb, $28); // scan unassoc time
  WirelessCommandInt(WIFI, $102, $82); // passive scan time


//  WirelessCommandInt(WIFI, 2, 1); // up (command has no parameters)


  WIFIDeviceSetBackplaneWindow(WIFI, WIFI^.sdregs);
  cfgwritel(WIFI, WIFI^.sdregs + IntStatus, 0);


  // we're not going to fill out the ssid or the mac or the extended parameters
  // or the channel list

  // and start the scan?
  WirelessCommandInt(WIFI, 49, 0);	// PASSIVE_SCAN */
  WirelessCommandInt(WIFI, 2, 0); // up (command has no parameters)


  // clear scan parameters.
  fillchar(scanparams, sizeof(scanparams), 0);

  // now setup what we need.
  scanparams.version := 1;
  scanparams.action := 1;   // start
  scanparams.sync_id:=NetSwapWord($1234);
  scanparams.params.scan_type := SCAN_TYPE_PASSIVE;
  scanparams.params.bss_type := BSS_TYPE_ANY; //bss_type need value
  fillchar(scanparams.params.bssid.octet[0], sizeof(ether_addr), $ff);  // broadcast address
  scanparams.params.nprobes := $ffffffff;
  scanparams.params.active_time := $ffffffff;
  scanparams.params.passive_time := $ffffffff;
  scanparams.params.home_time := $ffffffff;
  for i := 1 to 14 do
  begin
    scanparams.params.channel_list[i].chan:=i;
    scanparams.params.channel_list[i].other:=$2b;
  end;
  scanparams.params.channel_num:=14;
//  scanparams.params.channel_num := 0;   // this is channels and ssids in a 32 bit longword (all 0 for us)

  WirelessSetVar(WIFI, 'escan', @scanparams, sizeof(scanparams));


  // add interest in the scan result event so we can get a callback. Later we may pass this back
  // to the user part of the application as it's actually no use within this code really.
  RequestItemP := WIFIWorkerThread.AddRequest(0, [WLC_E_ESCAN_RESULT], @WirelessScanCallback);
  SemaphoreWaitEx(RequestItemP^.Signal, 20000);

  WIFIWorkerThread.DoneWithRequest(RequestItemP);
end;

procedure JoinCallback(Event : TWIFIEvent; EventRecordP : pwhd_event; RequestItemP : PWIFIRequestItem);
begin
  wifiloginfo(nil, 'wirless join callback: removing an event ' + inttostr(ord(event)) + ' from the list');
  RequestItemP^.RegisteredEvents := RequestItemP^.RegisteredEvents - [Event];
end;

procedure WirelessJoinNetwork(WIFI : PWIFIDevice; ssid : string; security_key : string);
const
  WPA2_SECURITY = $00400000;        // Flag to enable WPA2 Security
  AES_ENABLED   = $0004;            // Flag to enable AES Encryption
  WHD_SECURITY_WPA2_AES_PSK = (WPA2_SECURITY or AES_ENABLED);
  WLC_SET_WSEC = 134;
  DEFAULT_EAPOL_KEY_PACKET_TIMEOUT = 2500; // in milliseconds
  WSEC_MAX_PSK_LEN = 64;
  WSEC_PASSPHRASE = (1 shl 0);
  WLC_SET_WSEC_PMK = 268;
  WL_AUTH_OPEN_SYSTEM = 0;
  WL_AUTH_SAE = 3;
  WLC_SET_INFRA = 20;
  WLC_SET_AUTH = 22;
  WLC_SET_WPA_AUTH = 165;
  WPA2_AUTH_PSK = $0080;
  WLC_SET_SSID = 26;


type
  wsec_pmk = record
    key_len : word;
    flags : word;
    key : array[0..WSEC_MAX_PSK_LEN-1] of byte;
  end;

  wl_join_assoc_params = record
    bssid : ether_addr;
    bssid_cnt : word;
    chanspec_num : longword;
    chanspec_list : array[1..1] of word;
  end;

  wl_join_scan_params = record
    scan_type : byte;          // 0 use default, active or passive scan */
    nprobes : longint;         // -1 use default, number of probes per channel */
    active_time : longint;     // -1 use default, dwell time per channel for active scanning
    passive_time : longint;    // -1 use default, dwell time per channel for passive scanning
    home_time : longint;       // -1 use default, dwell time for the home channel between channel scans
  end;

  wl_extjoin_params = record
     ssid : wlc_ssid;                          // {0, ""}: wildcard scan */
     scan_params : wl_join_scan_params;
     assoc_params : wl_join_assoc_params;     // optional field, but it must include the fixed portion
                                              // of the wl_join_assoc_params_t struct when it does
                                              // present.
  end;




var
  data : array[0..1] of longword;
  psk : wsec_pmk;
  responseval : longword;
  auth_mfp : longword;
  wpa_auth : longword;
  ext_join_params : wl_extjoin_params;

  ints : longword;
  blockcount, remainder : longword;
  eventrecordp : pwhd_event;
  s : string;
  i : integer;
  NetworkJoined : boolean = false;
  simplessid : wlc_ssid;
  RequestEntryP : PWIFIRequestItem;

begin
  (*
   Assumptions:
     the access point exists
     it supports WPA2 security
  *)

//  MMC_DEFAULT_LOG_LEVEL:= MMC_LOG_LEVEL_DEBUG;

  // Set Wireless Security Type
  WirelessCommandInt(WIFI, WLC_SET_WSEC, WHD_SECURITY_WPA2_AES_PSK and $FF);

  // don't know where to get this from at the moment
  // but we want the first interface I think, so it's going to be either 0 or 1.
  data[0] := 0;  // this is the primary interface
  data[1] := 1;  // wpa security on
  WirelessSetVar(WIFI, 'bsscfg:sup_wpa', @data[0], sizeof(data));

  // Set the EAPOL version to whatever the AP is using (-1) */
  data[0] := 0;
  data[1] := longword(-1);
  WirelessSetVar(WIFI, 'bsscfg:sup_wpa2_eapver', @data[0], sizeof(data));

  // Send WPA Key
  // Set the EAPOL key packet timeout value, otherwise unsuccessful supplicant events aren't reported. If the IOVAR is unsupported then continue.
  data[0] := 0;
  data[1] := DEFAULT_EAPOL_KEY_PACKET_TIMEOUT;
  WirelessSetVar(WIFI, 'bsscfg:sup_wpa_tmo', @data, sizeof(data));

  fillchar(psk, sizeof(psk), 0);
  move(security_key[1], psk.key[0], length(security_key));
  psk.key_len := length(security_key);
  psk.flags := WSEC_PASSPHRASE;

  // Delay required to allow radio firmware to be ready to receive PMK and avoid intermittent failure
  sleep(1);

  WirelessIOCTLCommand(WIFI, WLC_SET_WSEC_PMK, @psk, sizeof(psk), true, @responseval, 4);

  // Set infrastructure mode = 0 (i think)
  WirelessCommandInt(WIFI, WLC_SET_INFRA, 0);

  // Set authentication type
 (* if (auth_type == WHD_SECURITY_WEP_SHARED)
  {
      auth = WL_AUTH_SHARED_KEY;
  }
  else if ( (auth_type == WHD_SECURITY_WPA3_SAE) || (auth_type == WHD_SECURITY_WPA3_WPA2_PSK) )
  {
      auth = WL_AUTH_SAE;
  }
  else
  {
      auth = WL_AUTH_OPEN_SYSTEM;  // looks like it's going to be this one but seems wrong?
  }*)
  WirelessCommandInt(WIFI, WLC_SET_AUTH, WL_AUTH_OPEN_SYSTEM);

  auth_mfp := 0;
  WirelessSetVar(WIFI, 'mfp', @auth_mfp, 4);

  // Set WPA authentication mode
  wpa_auth := WPA2_AUTH_PSK;
  WirelessIOCTLCommand(WIFI, WLC_SET_WPA_AUTH, @wpa_auth, sizeof(wpa_auth), true, @responseval, 4);


  // Join network
  fillchar(ext_join_params, sizeof(ext_join_params), 0);

  ext_join_params.ssid.SSID_len := length(ssid);
  move(ssid[1], ext_join_params.ssid.SSID[0], length(ssid));

  // hard coded to my router for now but will need to be gotten from
  // the scan performed first, ultimately.
  // also trying $ff as I saw that somewhere, but getting same result for
  // all at the moment so not sure if it is actually working.
  // I suspect not!

(*  ext_join_params.assoc_params.bssid.octet[0] := $04;
  ext_join_params.assoc_params.bssid.octet[1] := $a2;
  ext_join_params.assoc_params.bssid.octet[2] := $22;
  ext_join_params.assoc_params.bssid.octet[3] := $2c;
  ext_join_params.assoc_params.bssid.octet[4] := $d5;
  ext_join_params.assoc_params.bssid.octet[5] := $0f;*)
  fillchar(ext_join_params.assoc_params.bssid.octet[0], 6, $ff);

  ext_join_params.scan_params.scan_type := 0;
  ext_join_params.scan_params.active_time := -1;
  ext_join_params.scan_params.home_time := -1;
  ext_join_params.scan_params.nprobes := -1;
  ext_join_params.scan_params.passive_time := -1;
  ext_join_params.assoc_params.bssid_cnt := 0;

  // don't know if we need to do this or not.

  (*
  if (ap->channel)
  {
      ext_join_params->assoc_params.chanspec_num = (uint32_t)1;
      ext_join_params->assoc_params.chanspec_list[0] =
          (wl_chanspec_t)htod16( (ap->channel |
                                  GET_C_VAR(whd_driver, CHANSPEC_BW_20) | GET_C_VAR(whd_driver,
                                                                                    CHANSPEC_CTL_SB_NONE) ) );

      /* set band properly */
      wl_band_for_channel = whd_channel_to_wl_band(whd_driver, ap->channel);

      ext_join_params->assoc_params.chanspec_list[0] |= wl_band_for_channel;
  }
*)

  // finally, try and join the network.
  // temporarily commented out this join method to see if the other one works.
//  WirelessSetVar(WIFI, 'join', @ext_join_params, sizeof(ext_join_params));

  // this is, if I understand correctly, a simler join.
  fillchar(simplessid, sizeof(simplessid), 0);
  move(ssid[1], simplessid.SSID[0], length(ssid));
  simplessid.SSID_len:=length(ssid);
  WirelessIOCTLCommand(WIFI, WLC_SET_SSID, @simplessid, sizeof(simplessid), true, @responseval, 4);

  // probably need to register a signal for a group of events now (use a set maybe?) and then
  // that can be matched in ine worker thread and signalled as appropriate. This would be instead
  // of a request id as we don't have one in this instance. Could be done in the same queue
  // if we expand the properties.

  RequestEntryP := WIFIWorkerThread.AddRequest(0, [WLC_E_SET_SSID, WLC_E_START, WLC_E_LINK], @JoinCallback);

  // wait for 5 seconds.
  SemaphoreWaitEx(RequestEntryP^.Signal, 5000);

  if (RequestEntryP^.RegisteredEvents = []) then
    WIFILogInfo(nil, 'Successfully found all of the registered events')
  else
    WIFILogInfo(nil, 'There are still some events not found after the 5 second wait');

  WIFIWorkerThread.DoneWithRequest(RequestEntryP);
end;

procedure WirelessInit(WIFI : PWIFIDevice);
const
  MAC_ADDRESS_LEN = 6;
  WLC_SET_PM = 86;

type
  countryparams = record
    country_ie : array[1..4] of char;
    revision : longint;
    country_code : array[1..4] of char;
  end;

var
  version : array[1..250] of byte;
  countrysettings : countryparams;
  macaddress : array[0..MAC_ADDRESS_LEN-1] of byte;
begin
 // request the mac address of the wifi device
 fillchar(macaddress[0], sizeof(macaddress), 0);

// WIFI_DEFAULT_LOG_LEVEL:=WIFI_LOG_LEVEL_DEBUG;

 WIFILogInfo(nil, 'Requesting MAC address from the WIFI device...');
 WirelessGetVar(WIFI, 'cur_etheraddr', @macaddress[0], MAC_ADDRESS_LEN);

 WIFILogInfo(nil, 'WIFI Current MAC address is '
         + IntToHex(macaddress[0], 2) + ':'
         + IntToHex(macaddress[1], 2) + ':'
         + IntToHex(macaddress[2], 2) + ':'
         + IntToHex(macaddress[3], 2) + ':'
         + IntToHex(macaddress[4], 2) + ':'
         + IntToHex(macaddress[5], 2));

 // upload regulatory file - can't set country and join a network without this.
 WIFIDeviceUploadRegulatoryFile(WIFI);

 // do some further initialisation once the firmware is booted.
 WirelessSetInt(WIFI, 'assoc_listen', 10);

 // powersave
 if (WIFI^.chipid = 43430) or (WIFI^.chipid=$4345) then
   WirelessCommandInt(WIFI, WLC_SET_PM, 0)  // powersave off
 else
   WirelessCommandInt(WIFI, WLC_SET_PM, 2); // powersave fast

 WirelessSetInt(WIFI, 'bus:txglom', 0);
 WirelessSetInt(WIFI, 'bcn_timeout', 10);
 WirelessSetInt(WIFI, 'assoc_retry_max', 3);

 // get first 50 chars of the firmware version string
 WirelessGetVar(WIFI, 'ver', @version[1], 50);
 WIFILogDebug(nil, 'Firmware version string (partial): ' + buftostr(@version[1], 50));

 WirelessSetInt(WIFI, 'roam_off', 1);
 WirelessCommandInt(WIFI, $14, 1); // set infra 1
 WirelessCommandInt(WIFI, 10, 0);  // promiscuous

 // set country code
 WIFILogDebug(nil, 'Setting country code');

 countrysettings.country_ie[1] := 'G';
 countrysettings.country_ie[2] := 'B';
 countrysettings.country_ie[3] := #0;
 countrysettings.country_ie[4] := #0;
 countrysettings.country_code[1] := 'G';
 countrysettings.country_code[2] := 'B';
 countrysettings.country_code[3] := #0;
 countrysettings.country_code[4] := #0;
 countrysettings.revision := -1;

 WirelessSetVar(WIFI, 'country', @countrysettings, sizeof(countrysettings));
end;



constructor TWIFIWorkerThread.Create(CreateSuspended : boolean; AWIFI : PWIFIDevice);
begin
  inherited Create(CreateSuspended);
  FWIFI := AWIFI;

  FRequestQueueP := nil;
  FLastRequestQueueP := nil;
  FQueueProtect := CriticalSectionCreate;
end;

destructor TWIFIWorkerThread.Destroy;
begin
  // free memory allocated to the queue and release any semaphores.
  // do this later - most apps just get turned off on shutdown anyway!

  // release other resources.
  CriticalSectionDestroy(FQueueProtect);
  inherited Destroy;
end;

procedure TWIFIWorkerThread.dumpqueue;
var
  entryp : PWIFIRequestItem;
  count : integer;
begin
 CriticalSectionLock(FQueueProtect);
 try
   entryp := FRequestQueueP;
   count := 0;
   while (entryp <> nil) do
   begin
     wifiloginfo(nil, inttostr(count) + ' 0x' + inttohex(longword(entryp), 8)
          + ' 0x' + inttohex(psemaphoreentry(entryp^.signal)^.Signature, 8)
          + ' handle ' + inttostr(entryp^.signal)
          + ' request id ' + inttostr(entryp^.RequestID)
          );
     entryp := entryp^.nextp;
   end;

 finally
   CriticalSectionUnlock(FQueueProtect);
 end;
end;

function TWIFIWorkerThread.AddRequest(ARequestID : word; InterestedEvents : TWIFIEventSet; Callback : TWirelessEventCallback) : PWIFIRequestItem;
var
  ItemP : PWIFIRequestItem;
begin
  Result := nil;
  CriticalSectionLock(FQueueProtect);
  try
    //allocate structure
    getmem(ItemP, sizeof(TWIFIRequestItem));

    //store request id and create semaphore to signal when request is filled.
    ItemP^.RequestId := ARequestID;
    ItemP^.Signal:=SemaphoreCreate(0);
    ItemP^.NextP := nil;
    ItemP^.MsgP := nil;
    ItemP^.RegisteredEvents := InterestedEvents;
    ItemP^.Callback := Callback;

    //add to the end of the request list.
    if (FRequestQueueP = nil) then
      FRequestQueueP := ItemP
    else
      FLastRequestQueueP^.NextP := ItemP;

    FLastRequestQueueP := ItemP;
    Result := ItemP;
  finally
    CriticalSectionUnlock(FQueueProtect);
  end;
end;

procedure TWIFIWorkerThread.DoneWithRequest(ARequestItemP : PWIFIRequestItem);
var
  CurP, PrevP : PWIFIRequestItem;
begin
  CriticalSectionLock(FQueueProtect);

  try
    // find the request item in the queue
    CurP := FRequestQueueP;
    PrevP := nil;
    while (CurP <> ARequestItemP) and (CurP <> nil) do
    begin
       PrevP := CurP;
       CurP := CurP^.NextP;
    end;

    if (CurP <> nil) then
    begin
     // remove it from the queue
     if (PrevP <> nil) then
       PrevP^.NextP := CurP^.NextP
     else
       FRequestQueueP := CurP^.NextP;

     if (CurP = FLastRequestQueueP) then
       FLastRequestQueueP := PrevP;

     // dispose of the semaphore and free the memory it used
     SemaphoreDestroy(ARequestItemP^.Signal);
     if (ARequestItemP <> nil) then
       FreeMem(ARequestItemP^.MsgP);

     Freemem(ARequestItemP);
    end
    else
      WIFILogError(nil, 'Unable to locate item in the request queue');

  finally
    CriticalSectionUnLock(FQueueProtect);
  end;
end;

function TWIFIWorkerThread.FindRequest(ARequestId : word) : PWIFIRequestItem;
var
  CurP : PWIFIRequestItem;

begin
  Result := nil;

  CriticalSectionLock(FQueueProtect);
  try
    CurP := FRequestQueueP;
    while (CurP <> nil) and (CurP^.RequestID <> ARequestId) do
       CurP := CurP^.NextP;

  finally
    CriticalSectionUnLock(FQueueProtect);
  end;

  Result := CurP;
end;

function TWIFIWorkerThread.FindRequestByEvent(AEvent : longword) : PWIFIRequestItem;
var
  CurP : PWIFIRequestItem;
begin
  // find the first request item that has an interest in the specified event.
  // we really need to find a list of items but we can do that later.
  // let's start with the first one for testing purposes.
  Result := nil;

  CriticalSectionLock(FQueueProtect);
  try
    CurP := FRequestQueueP;
    while (CurP <> nil) and (not (TWIFIEvent(AEvent) in CurP^.RegisteredEvents)) do
      CurP := CurP^.NextP;

  finally
    CriticalSectionUnLock(FQueueProtect);
  end;

  Result := CurP;
end;

procedure TWIFIWorkerThread.Execute;
var
  istatus : longword;
  responseP  : PIOCTL_MSG = @ioctl_rxmsg;
  blockcount, remainder : longword;
  EventRecordP : pwhd_event;
  SequenceNumber : word;
  RequestEntryP : PWIFIRequestItem;
  scanresultp : pwl_escan_result;
  ssidstr : string;
  s : string;

begin
  while not terminated do
  begin
     // this polls for the interrupt status changing, which tells us there is some data to read.
     istatus := cfgreadl(FWIFI, FWIFI^.sdregs + IntStatus, 1);
     while (istatus and $40 <> $40) do
     begin
       MicrosecondDelay(20);
       istatus := cfgreadl(FWIFI, FWIFI^.sdregs + IntStatus, 2);
     end;

     // clear interrupt status (seems like writing the value back does this based on other drivers)
     cfgwritel(FWIFI, FWIFI^.sdregs + IntStatus, istatus);
     cfgreadl(FWIFI, FWIFI^.sdregs + IntStatus, 3);

     if SDIOWIFIDeviceReadWriteExtended(FWIFI, sdioRead, WLAN_FUNCTION, BAK_BASE_ADDR and $1ffff, false, ResponseP, 0, SDPCM_HEADER_SIZE,18) <> WIFI_STATUS_SUCCESS then
     begin
       wifilogerror(nil, 'Error trying to read SDPCM header');
       exit;
     end;

     // once we have a len, keep repeating the reads until no more data is left
     // this is signified by reading a length (at end of loop) and getting zero.
     // we do it this way because the interrupt flag may be set but the device might
     // receive more data in between us clearing the flag and attempting to read the
     // available data.

     while (ResponseP^.Len <> 0) do
     begin
       if ((responsep^.len + responsep^.notlen) <> $ffff) then
          WIFILogError(nil, 'IOCTL Header length failure: len='+inttohex(responsep^.len, 8) + ' notlen='+inttohex(responsep^.notlen, 8));

       if (ResponseP^.Len > SDPCM_HEADER_SIZE) then
       begin
         blockcount := (ResponseP^.Len-SDPCM_HEADER_SIZE) div 512;
         remainder := (ResponseP^.Len-SDPCM_HEADER_SIZE) mod 512;
       end
       else
       begin
        blockcount := 0;
        remainder := ResponseP^.Len-SDPCM_HEADER_SIZE; // still not right could go negative theoretically but unlikely unless wifi firmware had a bug.
       end;

       if (ResponseP^.Len <= IOCTL_MAX_BLKLEN) and (ResponseP^.Len > 0) then
       begin
         if (blockcount > 0) then
         begin
           if SDIOWIFIDeviceReadWriteExtended(FWIFI, sdioRead, WLAN_FUNCTION, BAK_BASE_ADDR and $1ffff, false, pbyte(responsep)+SDPCM_HEADER_SIZE, blockcount, 512,19) <> WIFI_STATUS_SUCCESS then
             wifilogerror(nil, 'Error trying to read blocks for ioctl response');
         end;

         if (remainder > 0) then
         begin
           if SDIOWIFIDeviceReadWriteExtended(FWIFI, sdioRead, WLAN_FUNCTION, BAK_BASE_ADDR and $1ffff, false, pbyte(responsep)+SDPCM_HEADER_SIZE + blockcount*512, 0, remainder,20) <> WIFI_STATUS_SUCCESS then
             wifilogerror(nil, 'Error trying to read blocks for ioctl response (len='+inttostr(responsep^.len)+')');
         end;

         // the channel has 4 bits flags in the lower nibble and 4 bits channel number in the upper nibble.
         case (responseP^.cmd.chan and $f) of
           0: begin
                // Now we have a message, we need to check the sequence id to see if there is a
                // thread waiting to be signaled for the response.

                SequenceNumber := (responseP^.cmd.flags >> 16) and $ffff;
                RequestEntryP := WIFIWorkerThread.FindRequest(SequenceNumber);

                if (RequestEntryP <> nil) then
                begin
                  // this isn't very efficient and will need attention later.
                 getmem(RequestEntryP^.MsgP, Sizeof(IOCTL_MSG));
                 move(ResponseP^, RequestEntryP^.MsgP^, ResponseP^.Len);

                 // tell the waiting thread the response is ready.
                 SemaphoreSignal(RequestEntryP^.Signal);
                end
                else
                  wifilogerror(nil, 'failed to find a request for sequence number ' + inttostr(sequencenumber));
              end;
           1: begin
                EventRecordP := pwhd_event(pbyte(responsep)+responsep^.cmd.hdrlen + 4);
                EventRecordP^.whd_event.status := NetSwapLong(EventRecordP^.whd_event.status);

                // see if there are any requests interested in this event, and if so trigger
                // the callbacks. We only do the first one at the moment; we need a list eventually.

                RequestEntryP := WIFIWorkerThread.FindRequestByEvent(NetSwapLong(EventRecordP^.whd_event.event_type));
                if (RequestEntryP <> nil) and (RequestEntryP^.Callback <> nil) then
                begin
                  RequestEntryP^.Callback(TWIFIEvent(NetSwapLong(EventRecordP^.whd_event.event_type)), EventRecordP, RequestEntryP);
                end
                else
                  WIFILogDebug(nil, 'there was no interest in event ' + IntToStr(NetSwapLong(EventRecordP^.whd_event.event_type)));

(*                wifiloginfo(nil, 'D Event received - ResponseP^.Len='+inttostr(ResponseP^.Len)
                                 + ' headerlen=' + inttostr(responsep^.cmd.hdrlen)
                                 + ' event status=' + inttostr(EventRecordP^.whd_event.status)
                                 + ' event type ' + IntToStr(NetSwapLong(EventRecordP^.whd_event.event_type))
                                 + ' auth_type ' + inttostr(NetSwapLong(EventRecordP^.whd_event.auth_type))
                                 + ' datalen='+inttostr(NetSwapLong(EventRecordP^.whd_event.datalen)));*)
           (*
                wifiloginfo(nil, 'destination address from event ' + inttohex(EventRecordP^.eth.destination_address[0],2)
                                       + ' ' +inttohex(EventRecordP^.eth.destination_address[1],2)
                                       + ' ' +inttohex(EventRecordP^.eth.destination_address[2],2)
                                       + ' ' +inttohex(EventRecordP^.eth.destination_address[3],2)
                                       + ' ' +inttohex(EventRecordP^.eth.destination_address[4],2)
                                       + ' ' +inttohex(EventRecordP^.eth.destination_address[5],2));
                wifiloginfo(nil, 'source address from event ' + inttohex(EventRecordP^.eth.source_address[0],2)
                                       + ' ' +inttohex(EventRecordP^.eth.source_address[1],2)
                                       + ' ' +inttohex(EventRecordP^.eth.source_address[2],2)
                                       + ' ' +inttohex(EventRecordP^.eth.source_address[3],2)
                                       + ' ' +inttohex(EventRecordP^.eth.source_address[4],2)
                                       + ' ' +inttohex(EventRecordP^.eth.source_address[5],2));

                wifiloginfo(nil, 'station address from event ' + inttohex(EventRecordP^.whd_event.addr[0],2)
                                       + ' ' +inttohex(EventRecordP^.whd_event.addr[1],2)
                                       + ' ' +inttohex(EventRecordP^.whd_event.addr[2],2)
                                       + ' ' +inttohex(EventRecordP^.whd_event.addr[3],2)
                                       + ' ' +inttohex(EventRecordP^.whd_event.addr[4],2)
                                       + ' ' +inttohex(EventRecordP^.whd_event.addr[5],2));

                wifiloginfo(nil, 'event type ' + IntToStr(NetSwapLong(EventRecordP^.whd_event.event_type)) + ' auth_type ' + inttostr(NetSwapLong(EventRecordP^.whd_event.auth_type))
                                 + ' datalen='+inttostr(NetSwapLong(EventRecordP^.whd_event.datalen)));

                wifiloginfo(nil, 'version ' + inttostr(EventRecordP^.whd_event.version));
                wifiloginfo(nil, 'version swapped ' + inttostr(NetSwapWord(EventRecordP^.whd_event.version)));*)

                if (NetSwapLong(EventRecordP^.whd_event.event_type) = 16) then
                begin
                   hexdump(pbyte(@EventRecordP^.whd_event + sizeof(whd_event_msg)), NetSwapLong(EventRecordP^.whd_event.datalen));
                end;

                // note this has already been swapped above.
                if (NetSwapLong(EventRecordP^.whd_event.event_type) = 2) then
                  case EventRecordP^.whd_event.status of
                     3 : wifiloginfo(nil, 'Could not find the network that was specified');
                     0 : wifiloginfo(nil, 'the specified network was sucessfully located');
                     else
                       wifiloginfo(nil, 'some other status was received that we dont have a definition for');
                  end;

                // scan result
(*                if (NetSwapLong(eventrecordp^.whd_event.event_type) = 69) then
                begin
                  scanresultp := pwl_escan_result(pbyte(@eventrecordp^.whd_event + sizeof(whd_event_msg)));
                  ssidstr := buftostr(@scanresultp^.bss_info[1].SSID[0], scanresultp^.bss_info[1].SSID_len, true);
                  if (ssidstr = '') then
                    ssidstr := '<hidden>';

                  s := 'SSID='+ssidstr
                                + ' event status=' + inttostr(eventrecordp^.whd_event.status)
                                + ' buflen = '+inttostr(scanresultp^.buflen)
                                + ' channel = ' +inttostr(scanresultp^.bss_info[1].chanspec and $ff)
                                + ' MAC = ' +inttohex(scanresultp^.bss_info[1].BSSID.octet[0], 2) + ':'
                                + inttohex(scanresultp^.bss_info[1].BSSID.octet[1], 2) + ':'
                                + inttohex(scanresultp^.bss_info[1].BSSID.octet[2], 2) + ':'
                                + inttohex(scanresultp^.bss_info[1].BSSID.octet[3], 2) + ':'
                                + inttohex(scanresultp^.bss_info[1].BSSID.octet[4], 2) + ':'
                                + inttohex(scanresultp^.bss_info[1].BSSID.octet[5], 2);
                  if (eventrecordp^.whd_event.status = 8) then
                    s := s + ' Partial scan result';
                  WIFILogInfo(nil, s);
              end; *)
           end;
           2: begin
                wifiloginfo(nil, 'network packet received - ignore');
              end;
         else
           wifiloginfo(nil,'dont know what this one is 0x'+inttohex(responseP^.cmd.chan and $f, 2));
         end
       end
       else
         if (ResponseP^.Len > 0) then
           WIFILogError(nil, 'could not read a large message into an undersized buffer (len='+inttostr(responsep^.len)+')');

       // read next sdpcm header (may not be one present in which case everything will be zero including length)
       if SDIOWIFIDeviceReadWriteExtended(FWIFI, sdioRead, WLAN_FUNCTION, BAK_BASE_ADDR and $1ffff, false, ResponseP, 0, SDPCM_HEADER_SIZE,21) <> WIFI_STATUS_SUCCESS then
       begin
         wifilogerror(nil, 'Error trying to read SDPCM header');
         exit;
       end;
     end;
  end;
end;


initialization
  WIFIInit;

end.


(*
whd_thread.c does the packet send and receive

whd_bus_sdio_protocol.c  whd_bus_sdio_read_frame reads a frame from function 2 wihch is the wlan function.   This is the guts of the packet receive code that needs to be passed up to the Ultibo layer and we'll need to replicate it.
*)
