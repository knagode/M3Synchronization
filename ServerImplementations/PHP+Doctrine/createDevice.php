<?


require_once("../doctrine_bootstrap.php");
require("functionsLibrary.php");


error_reporting(E_ALL);
ini_set('display_errors', '1');


if(isset($_POST["email"])){
	
	$userDevice = new UserDevice();
	$userDevice->datetimeAdded = date("Y-m-d H:i:s");
	$userDevice->userId = null;  // userId is set when email is confirmed
	$userDevice->isActivated = 0;
	$userDevice->secureCode = random_string(100);
	$userDevice->email = $_POST["email"];
 	$userDevice->activationCode = random_string(30); // activationCode should not be null
	$userDevice->save();
	
	$user = Doctrine_Query::create()->from("User")->where("email=?", $userDevice->email)->andWhere("activated=1")->fetchOne();
	
	if($user) {
		echo '{"hasError":0, "status":"enterPasswordToCreateUser", "userDeviceId":'.$userDevice->id.',"secureCode":"'.$userDevice->secureCode.'"}';
	} else {
		
		$userDevice->sendActivationEmail(); // send instructions with link to activate email
		
		echo '{"hasError":0, "status":"activateToCreateUser", "userDeviceId":'.$userDevice->id.',"secureCode":"'.$userDevice->secureCode.'"}';
	}
		

} else {
	echo '{"hasError":1, "errorMessage":"email not defined!"}';
}




?>