<?
	
    error_reporting(E_ALL);
    ini_set('display_errors', '1');


    $syncSpecifications = json_decode(file_get_contents("syncSpecifications.json"), true);


    $classToSync = null;

    if(isset($_GET["class"])) {
        //debug($syncSpecifications);
        //print_r($syncSpecifications);

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

	require_once("../doctrine_bootstrap.php");
	require_once("functionsLibrary.php"); 
	
	$userDevice = getActiveDevice();
			
	if($userDevice) {
		
		if($userDevice->userId) {
			
			$query = Doctrine_Query::create()
						->from($classToSync)
						->where("userId=?", $userDevice->userId);
		
			if(isset($_POST["timestampLastSync"])) {
				$query->andWhere("timestampModified > ? OR timestampServerModified > ?", array(gmdate("Y-m-d H:i:s", (int)$_POST["timestampLastSync"]), gmdate("Y-m-d H:i:s", (int)$_POST["timestampLastSync"])));
			} else {
				//!!! default fields should stay deleted! $query->addWhere("isDeleted!=1"); // we sync on ne device - there is no need to send deleted data to device
			}
			
			$entities = $query->execute();
			
			echo '{"timestampServer":'.gmmktime().', "items":[';
			
			$isFirst = true;
			foreach($entities as $entity) {
				if (!$isFirst) {
					echo ",";
				} else {
					$isFirst = false;
				}		

				echo '{"remoteId":'.$entity->id.',"isDeleted":'.($entity->isDeleted?"true":"false").', "timestampInserted":'.strtotime($entity->timestampInserted).', "timestampModified":'.strtotime($entity->timestampModified).' ';
				
				$fields = $syncSpecifications[$classToSync]["fieldsToSyncBothWays"];
				

				$table = Doctrine::getTable($classToSync);
				
				$columnDefinitions = $table->getColumns();
				//echo "<pre>"; print_r($columnDefinitions);
				
				foreach($fields as $field) {
					
					$lowerCasedField = strtolower($field);
					
					echo ", ";
					
					echo '"'.$field.'":';
					//echo $columnDefinitions[$lowerCasedField]["type"];
					if($columnDefinitions[$lowerCasedField]["type"] == "integer"){ // is bool or int
						
						if($columnDefinitions[$lowerCasedField]["length"] == "1") {
							if ($entity->$field) {
								echo "true";
							} else {
								echo "false";
							}
						} else {
							echo (int) $entity->$field;
						}
						
					} else if($columnDefinitions[$lowerCasedField]["type"] == "float"){
						echo (double) $entity->$field;
					} else {
						echo '"'.$entity->$field.'"'; 
					}
						
					
				}
				
				echo ' }';
			}
			echo "] }";
		} else {
			echo '{"hasError":true, "errorMessage":"Device is not Activated", "status":"deviceNotActivated"}';
                }
	} 
	
?>
