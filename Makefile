


abi:
	jq '.abi' out/NGODAO.sol/NGODAO.json > NGODAO.abi

go-bindings:
	jq '.abi' out/NGODAO.sol/NGODAO.json > NGODAO.abi
	abigen --abi NGODAO.abi --pkg ngo --out ngo_dao.go

typescript-bindings:
	npx typechain --target ethers-v5 --out-dir src/types ./out/NGODAO.sol/*.json