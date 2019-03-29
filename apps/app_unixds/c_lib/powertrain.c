// cc -o powertrain powertrain.c -lcsunixds
#include <csunixds.h>
#include <stdio.h>
#include <assert.h>

#define NAME_COUNT (sizeof(names) / sizeof(names[0]))

static const char *const names[] = {
	"ChassisCANhs2:AccActvnOk",
	"ChassisCANhs2:AccActvnOk_UB",
	"ChassisCANhs2:AccInhbByPrpsn",
	"ChassisCANhs2:AccInhbByPrpsn_UB",
	"ChassisCANhs2:AccStbOk",
	"ChassisCANhs2:AccStbOk_UB",
	"ChassisCANhs2:AccrPedlRatGrdt",
	"ChassisCANhs2:AccrPedlRatGrdt_UB",
	"ChassisCANhs2:AdjSpdLimnActvnOk",
	"ChassisCANhs2:AdjSpdLimnActvnOk_UB",
	"ChassisCANhs2:AdjSpdLimnStbOk",
	"ChassisCANhs2:AdjSpdLimnStbOk_UB",
	"ChassisCANhs2:CrsCtrlrStbOk",
	"ChassisCANhs2:CrsCtrlrStbOk_UB",
	"ChassisCANhs2:DispOfPrpsnMod",
	"ChassisCANhs2:DispOfPrpsnMod_UB",
	"ChassisCANhs2:DispOfPrpsnPwrPercAct",
	"ChassisCANhs2:DispOfPrpsnPwrPercAct_UB",
	"ChassisCANhs2:EngN",
	"ChassisCANhs2:EngNChks",
	"ChassisCANhs2:EngNCntr",
	"ChassisCANhs2:EngNSafeEngNGrdt",
	"ChassisCANhs2:EngNSafe_UB",
	"ChassisCANhs2:HvCooltHeatrEnad",
	"ChassisCANhs2:HvCooltHeatrEnad_UB",
	"ChassisCANhs2:HvEgyCnsAllwdForClima",
	"ChassisCANhs2:HvEgyCnsAllwdForClima_UB",
	"ChassisCANhs2:PrpsnHvBattUsgModAct",
	"ChassisCANhs2:PrpsnHvBattUsgModAct_UB",
	"ChassisCANhs2:PrpsnHvBattUsgOfChrgBlkd",
	"ChassisCANhs2:PrpsnHvBattUsgOfChrgBlkd_UB",
	"ChassisCANhs2:PrpsnHvBattUsgOfDispSoc",
	"ChassisCANhs2:PrpsnHvBattUsgOfDispSoc_UB",
	"ChassisCANhs2:PrpsnHvBattUsgOfHldBlkd",
	"ChassisCANhs2:PrpsnHvBattUsgOfHldBlkd_UB",
	"ChassisCANhs2:PrpsnHvBattUsgOfHldSmtBlkd",
	"ChassisCANhs2:PrpsnHvBattUsgOfHldSmtBlkd_UB",
	"ChassisCANhs2:PrpsnStsForAcc",
	"ChassisCANhs2:PrpsnStsForAcc_UB",
	"ChassisCANhs2:PtBrkTqRgnAtAxleReAct",
	"ChassisCANhs2:PtBrkTqRgnAtAxleReAct_UB",
	"ChassisCANhs2:RlyCrashForHvsysReq",
	"ChassisCANhs2:RlyCrashForHvsysReq_UB",
	"ChassisCANhs:PtTqAtAxleFrntAddReq",
	"ChassisCANhs:PtTqAtAxleFrntMaxReq",
	"ChassisCANhs:PtTqAtAxleFrntMaxReq_UB",
	"ChassisCANhs:PtTqAtAxleFrntMinReq",
	"ChassisCANhs:TqRednDurgCllsnMtgtnByBrkg",
	"ChassisCANhs:TqRednDurgCllsnMtgtnByBrkg_UB",
	"PropulsionCANhs2:AccrPedlLnr",
	"PropulsionCANhs2:AccrPedlLnr_UB",
	"PropulsionCANhs2:CrShMaxTqKd",
	"PropulsionCANhs2:CrShMaxTqKd",
	"PropulsionCANhs2:CrShMaxTqKd_UB",
	"PropulsionCANhs2:CrShMaxTqKd_UB",
	"PropulsionCANhs2:CrShMinTq",
	"PropulsionCANhs2:CrShMinTqCont",
	"PropulsionCANhs2:CrShMinTqCont_UB",
	"PropulsionCANhs2:CrShMinTq_UB",
	"PropulsionCANhs2:CrsFcnIndx",
	"PropulsionCANhs2:CrsFcnIndx_UB",
	"PropulsionCANhs2:CrsFcnTrqReq",
	"PropulsionCANhs2:CrsFcnTrqReq_UB",
	"PropulsionCANhs2:IsgModReq",
	"PropulsionCANhs2:IsgModReq_UB",
	"PropulsionCANhs2:PtCluTqReq",
	"PropulsionCANhs2:PtCluTqReq_UB",
	"PropulsionCANhs2:PtGearAct",
	"PropulsionCANhs2:PtGearAct_UB",
	"PropulsionCANhs2:TrsmTqRat",
	"PropulsionCANhs2:TrsmTqRat_UB",
	"PropulsionCANhs2:WhlMotSysModReq",
	"PropulsionCANhs2:WhlMotSysModReq_UB",
	"PropulsionCANhs:VehSpdLgtSafe",
};

int main(int argc, char *argv[]) {
	assert(cs_initialize(NULL) == CS_OK);

	cs_value_t values[NAME_COUNT];
	assert(cs_read(NAME_COUNT, names, values) == CS_OK);

	int i;
	for (i=0; i<NAME_COUNT; i++) {
		printf("%4s %-45s : %7.7f\n",
				values[i].value_f64 != 0.0 ? "-->" : "",
				names[i],
				values[i].value_f64
				);
	}

	assert(cs_shutdown() == CS_OK);
	return 0;
}
