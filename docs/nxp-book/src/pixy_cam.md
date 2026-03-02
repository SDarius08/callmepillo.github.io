# Camera Pixy

Camera Pixy utilizeaza un procesor NXP LPC4330TFBGA100 care poate fi programat fie prin interfata usb, fie prin pinii J5 ai placii.

[Poza procesor]

## Programare prin USB

Interfata USB este conectata la pinii USB0_DP, USB0_DM, USB0_VBUS, USB0_ID.
{_citeste data sheet procesor si vezi cum functioneaza acesti pini_}
[Poza interfatare USB]

## Programare

Cei 10 pini J5 ai camerei Pixy sunt exposi prin pad-uri. Acestia sunt conectati la interfata JTAG a placii (JTAG_TDI, JTAG_TDO, JTAG_TMS, JTAG_TRST).
{_citeste data sheet procesor, programare prin jtag_}
[Poza interfatare JTAG]

## Considerente

Pentru ca firmware-ul este special dezvoltat pentru aceasta placa si este complex, va trebui foarte bine analizat modul in care interactioneaza componentele placii.
