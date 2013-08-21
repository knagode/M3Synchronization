<?
	


error_reporting(E_ALL);
ini_set('display_errors', '1');
$root =  dirname(__FILE__);
require_once($root."/../doctrine_bootstrap.php");


	
function getActiveDevice() {

	if(!isset($_POST["userDeviceId"])) {
		echo '{"hasError":true, "errorMessage":"userDeviceId not defined in POST"}';
		exit;
	}

	$userDevice = Doctrine::getTable("UserDevice")->find($_POST["userDeviceId"]);
	if($userDevice) {
		if($userDevice->secureCode == $_POST["secureCode"]) {
			return $userDevice;
		} else {
			echo '{"hasError":true, "errorMessage":"secureCode is not correct!"}';
			exit;
		}

	} else {
		echo '{"hasError":true, "errorMessage":"device does not exist! userDeviceId='.((int) $_POST["userDeviceId"]).'"}';
		exit;
	}

}

function json_encode_with_numbers($array) {
	if(is_array($array)) {
		if(count($array)>0 && array_keys($array) !== range(0, count($array) - 1)) {
			echo '{'; 

			$isFirst = true;
			foreach($array as $key=>$item) {
				if(!$isFirst) {
					echo ",";
				}
				echo '"'.$key.'":';
				json_encode_with_numbers($item);
				$isFirst = false;
			}
			echo '}';
		} else {
			echo '['; 
			$isFirst = true;
			foreach($array as $item) {
				if(!$isFirst) {
					echo ",";
				}
				json_encode_with_numbers($item);
				$isFirst = false;
			}
			echo ']';
		}
	} else {
		if(is_numeric($array)) {
			echo $array;
		} elseif ($array == null) {
			echo "null";
		} else {
			echo '"'.str_replace(array('"', '\\'), array('\"', '\\\\'), $array).'"'; // escape special chars
		}

	}

}

function markAsModified($entity) {
	$entity->timestampModified = $entity->timestampServerModified = gmmktime();
}

function markAsJustInserted($entity) {
	markAsModified($entity);
	$entity->timestampInserted = $entity->timestampModified;
}


function output_json_no_error() {
	echo '{"hasError":false}';
}


?>