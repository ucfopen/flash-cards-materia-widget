<?php
/**
 * {ADD YOUR DOCUMENTATION HERE}
 *
 * 
 *
 * The widget score module
 *
 * @package	    Materia
 * @subpackage  scoring
 * @category    Modules
 * @author      ADD NAME HERE
 *
 * @group App
 * @group Materia
 * @group Score
 * @group test
 */

namespace Materia;

class Score_Modules_test extends Score_Module
{

	/**
	 * A basic example of what methods this class should override.
	 * @param  object $log Any data saved to the server by your widget (usually question or performance data).
	 * @return [type]      [description]
	 */
	// public function check_answer($log)
	// {
	// 	if (isset($this->questions[$log->item_id]))
	// 	{
	// 		$question = $this->questions[$log->item_id];
	// 		foreach ($question->answers as $answer)
	// 		{
	// 			if ($log->text == $answer['text'])
	// 			{
	// 				return $answer['value'];
	// 				break;
	// 			}
	// 		}
	// 	}
	// 	
	// 	return 0;
	// }

}
