<?

	error_reporting(E_ALL);
	ini_set('display_errors', '1');

	
	require_once("functionsLibrary.php");
	require_once("../doctrine_bootstrap.php");

	$syncSpecifications = json_decode(file_get_contents("syncSpecifications.json"), true);

	$classToSync = null;
	
	if(isset($_GET["class"])) {

		if(isset($syncSpecifications[$_GET["class"]])) {
			$classToSync = $_GET["class"];
		} else {
			echo '{"hasError":true, "errorMessage":"This class is not valide to sync"}';
			exit;
		}
		
		
	} else {
		
		echo '{"hasError":true, "errorMessage":"No class/table defined in GET"}';
		exit;
	}
	
	
	
	if(isset($_POST["json"])) {

		$userDevice = getActiveDevice();
		
		

		if($userDevice) {

			$json = json_decode(stripslashes($_POST["json"]), true);
			
			
			$entity = null;
			
			
			$table = Doctrine::getTable($classToSync);
				
			$columnDefinitions = $table->getColumns();
			
			
			// check for duplicates
			if(isset($syncSpecifications[$classToSync]["uniqueFields"]) && count($syncSpecifications[$classToSync]["uniqueFields"])) {
				$query = Doctrine_Query::create()->from($classToSync);
				
				foreach($syncSpecifications[$classToSync]["uniqueFields"] as $field) {
					
					$lowerCasedField = strtolower($field);
					$json[$field] = round($json[$field],2);
					$query->addWhere($field."=?", $json[$field]);
				}
				$entity = $query->fetchOne();
				
			} 
			
			
			if(!$entity) {
				$entity = new $classToSync();
			}
			

			// remove array to prevent relations conflict with doctrine (Dotrine tries to put arrays into relations automatically from array)
			$jsonCopy = $json;
			foreach($jsonCopy as $key=>$item){
				if(is_array($item)){
					unset($jsonCopy[$key]);
				}
			}
	
				
			if(isset($_POST["remoteId"])) {
				$tmpEntity = Doctrine::getTable($classToSync)->find($_POST["remoteId"]);
			
				if($tmpEntity and $userDevice->userId and $userDevice->userId == $tmpEntity->userId) {
					$entity = $tmpEntity;
				} else {
					die('{"hasError":true, "errorMessage":"Send dirty data without activation is not yet implemented USER.id='.$userDevice->userId.'   POST.remoteId='.$_POST["remoteId"].'"}');
				}
			} 
			
			if (!$entity->timestampServerModified or $json["timestampModified"] > $entity->timestampModified) { // only save new entity or in case we send data which is newer than server data
				$entity->fromArray($jsonCopy);
				$entity->timestampModified = gmdate("Y-m-d H:i:s", (int)$json["timestampModified"]);
				$entity->timestampInserted = gmdate("Y-m-d H:i:s", (int)$json["timestampInserted"]);
				$entity->timestampServerModified = date("Y-m-d H:i:s", gmmktime());
				

				// correct values do prevent Doctrine validation errors
				foreach ($syncSpecifications[$classToSync]["fieldsToSyncBothWays"] as $field) {
					$lowerCasedField = strtolower($field);

					if($columnDefinitions[$lowerCasedField]["type"] == "float") {
						$round = 2;

						$entity->$field = round($json[$field],$round);
					} else if($columnDefinitions[$lowerCasedField]["type"] == "integer" && $columnDefinitions[$lowerCasedField]["length"]) { // bool
						if($entity->$field) {
							$entity->$field = 1;
						} else {
							$entity->$field = 0;
						}
					}
					
				}
				
				if($userDevice->userId && isset($entity->userId)){
					$entity->userId = $userDevice->userId;
				}
				if(isset($entity["userDeviceId"])) {
					$entity->userDeviceId = $userDevice->id;
				}
				
			      $entity->save();
					
					
				if(isset($syncSpecifications[$classToSync]["serverAfterSave"])) { // custom save action 
					$function = $syncSpecifications[$classToSync]["serverAfterSave"];
					if($function){
						require_once("sync".ucfirst($function).".php");
						$function($json, $entity);
					}
					
				}				
			}
				

			$serverDatetimeString = ', "timestampServer":'.gmmktime();
			

			echo '{"hasError":false, "message":"saved", "remoteId":'.$entity->id.''.$serverDatetimeString.'}';
			
		} else {
			echo '{"hasError":true, "errorMessage":"device does not exist"}';
		}
		
	} else {
		echo '{"hasError":true, "errorMessage":"POST format is not OK"}';
	}

?>