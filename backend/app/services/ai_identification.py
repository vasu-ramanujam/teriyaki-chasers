"""
AI-powered wildlife identification service
"""
import os
import base64
import requests
import json
import asyncio
from typing import List, Optional, Dict, Any
from openai import OpenAI
from app.schemas import IdentificationCandidate

class AIIdentificationService:
    def __init__(self):
        self.openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.inaturalist_api_key = os.getenv("INATURALIST_API_KEY")
    
    async def identify_photo(self, image_data: bytes) -> List[IdentificationCandidate]:
        """
        Identify wildlife from photo using OpenAI GPT-4 Vision with iNaturalist fallback
        """
        # Step 1: Try OpenAI GPT-4 Vision first
        openai_result = await self._try_openai_photo_identification(image_data)
        
        if openai_result and self._is_high_confidence(openai_result):
            return openai_result
        
        # Step 2: If OpenAI failed or low confidence, try iNaturalist
        inaturalist_result = await self._try_inaturalist_photo_identification(image_data)
        
        if inaturalist_result:
            # If we have both results, compare and choose the best
            if openai_result:
                return self._compare_and_choose_best(openai_result, inaturalist_result)
            return inaturalist_result
        
        # Step 3: If both failed, return OpenAI result (even if low confidence) or empty
        return openai_result or []
    
    async def _try_openai_photo_identification(self, image_data: bytes) -> Optional[List[IdentificationCandidate]]:
        """Try OpenAI GPT-4 Vision for photo identification"""
        try:
            # Compress image if too large (>2MB)
            if len(image_data) > 2 * 1024 * 1024:
                image_data = self._compress_image(image_data)
            
            # Encode image to base64
            image_base64 = base64.b64encode(image_data).decode('utf-8')
            
            response = self.openai_client.chat.completions.create(
                model="gpt-4-vision-preview",
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": """You are an expert wildlife biologist. Analyze this animal photo and identify the species. 
                                Return a JSON response with the following structure:
                                {
                                    "species_name": "Common name of the animal",
                                    "scientific_name": "Scientific name (Genus species)",
                                    "confidence_score": 0.95,
                                    "alternative_species": [
                                        {"name": "Alternative species", "confidence": 0.8}
                                    ]
                                }
                                
                                Be as specific as possible. If you can only identify the family or genus, indicate that in the response.
                                Confidence should be between 0.0 and 1.0."""
                            },
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:image/jpeg;base64,{image_base64}"
                                }
                            }
                        ]
                    }
                ],
                max_tokens=500,
                timeout=30
            )
            
            # Parse JSON response
            content = response.choices[0].message.content
            result = self._parse_openai_response(content)
            
            if result:
                return [
                    IdentificationCandidate(
                        species_id=f"openai_{result['species_name'].lower().replace(' ', '_')}",
                        label=result['species_name'],
                        score=result['confidence_score']
                    )
                ]
            
        except Exception as e:
            print(f"OpenAI photo identification failed: {e}")
        
        return None
    
    async def identify_audio(self, audio_data: bytes) -> List[IdentificationCandidate]:
        """
        Identify wildlife from audio using OpenAI Whisper + GPT-4 with Merlin Bird ID fallback
        """
        # Step 1: Try OpenAI Whisper + GPT-4 first
        openai_result = await self._try_openai_audio_identification(audio_data)
        
        if openai_result and self._is_high_confidence(openai_result):
            return openai_result
        
        # Step 2: If OpenAI failed or low confidence, try Merlin Bird ID
        merlin_result = await self._try_merlin_bird_identification(audio_data)
        
        if merlin_result:
            # If we have both results, compare and choose the best
            if openai_result:
                return self._compare_and_choose_best(openai_result, merlin_result)
            return merlin_result
        
        # Step 3: If both failed, return OpenAI result (even if low confidence) or empty
        return openai_result or []
    
    async def _try_openai_audio_identification(self, audio_data: bytes) -> Optional[List[IdentificationCandidate]]:
        """Try OpenAI Whisper + GPT-4 for audio identification"""
        try:
            # Limit audio to 30 seconds for cost optimization
            audio_file = self._save_temp_audio(audio_data)
            
            with open(audio_file, "rb") as f:
                transcript = self.openai_client.audio.transcriptions.create(
                    model="whisper-1",
                    file=f,
                    response_format="text"
                )
            
            # Use GPT-4 to identify species from transcript
            response = self.openai_client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {
                        "role": "system",
                        "content": "You are an expert wildlife biologist specializing in animal sounds and calls."
                    },
                    {
                        "role": "user",
                        "content": f"""Based on this audio transcript of an animal sound: "{transcript}"
                        
                        Identify the most likely species. Return JSON:
                        {{
                            "species_name": "Common name",
                            "scientific_name": "Scientific name",
                            "confidence_score": 0.9
                        }}"""
                    }
                ],
                max_tokens=200,
                timeout=30
            )
            
            # Parse JSON response
            content = response.choices[0].message.content
            result = self._parse_openai_response(content)
            
            if result:
                return [
                    IdentificationCandidate(
                        species_id=f"openai_audio_{result['species_name'].lower().replace(' ', '_')}",
                        label=result['species_name'],
                        score=result['confidence_score']
                    )
                ]
            
        except Exception as e:
            print(f"OpenAI audio identification failed: {e}")
        finally:
            # Clean up temp file
            if 'audio_file' in locals():
                os.unlink(audio_file)
        
        return None
    
    async def _try_inaturalist_photo_identification(self, image_data: bytes) -> Optional[List[IdentificationCandidate]]:
        """Try iNaturalist API for photo identification"""
        try:
            # iNaturalist computer vision API
            headers = {
                'Authorization': f'Bearer {self.inaturalist_api_key}' if self.inaturalist_api_key else None
            }
            
            files = {'image': image_data}
            response = requests.post(
                'https://api.inaturalist.org/v1/identify',
                files=files,
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                results = data.get('results', [])
                
                if results:
                    # Get top result
                    top_result = results[0]
                    taxon = top_result.get('taxon', {})
                    
                    return [
                        IdentificationCandidate(
                            species_id=f"inaturalist_{taxon.get('id', 'unknown')}",
                            label=taxon.get('preferred_common_name', 'Unknown Species'),
                            score=top_result.get('score', 0.5)
                        )
                    ]
            
        except Exception as e:
            print(f"iNaturalist photo identification failed: {e}")
        
        return None
    
    async def _try_merlin_bird_identification(self, audio_data: bytes) -> Optional[List[IdentificationCandidate]]:
        """Try Merlin Bird ID API for audio identification"""
        try:
            # Merlin Bird ID API (Cornell Lab)
            # Note: This is a simplified implementation
            # In production, you'd use the actual Merlin API
            
            files = {'audio': audio_data}
            response = requests.post(
                'https://api.merlin.allaboutbirds.org/identify',
                files=files,
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                predictions = data.get('predictions', [])
                
                if predictions:
                    top_prediction = predictions[0]
                    
                    return [
                        IdentificationCandidate(
                            species_id=f"merlin_{top_prediction.get('species_id', 'unknown')}",
                            label=top_prediction.get('species', 'Unknown Bird'),
                            score=top_prediction.get('confidence', 0.5)
                        )
                    ]
            
        except Exception as e:
            print(f"Merlin Bird ID identification failed: {e}")
        
        return None
    
    def _is_high_confidence(self, candidates: List[IdentificationCandidate]) -> bool:
        """Check if the identification has high confidence"""
        if not candidates:
            return False
        return candidates[0].score >= 0.8
    
    def _compare_and_choose_best(self, result1: List[IdentificationCandidate], 
                                result2: List[IdentificationCandidate]) -> List[IdentificationCandidate]:
        """Compare two identification results and choose the best one"""
        if not result1:
            return result2
        if not result2:
            return result1
        
        # Choose the result with higher confidence
        if result1[0].score >= result2[0].score:
            return result1
        return result2
    
    def _parse_openai_response(self, content: str) -> Optional[Dict[str, Any]]:
        """Parse OpenAI JSON response"""
        try:
            # Extract JSON from response (handle cases where response includes extra text)
            start_idx = content.find('{')
            end_idx = content.rfind('}') + 1
            
            if start_idx != -1 and end_idx > start_idx:
                json_str = content[start_idx:end_idx]
                return json.loads(json_str)
        except Exception as e:
            print(f"Failed to parse OpenAI response: {e}")
        
        return None
    
    def _compress_image(self, image_data: bytes) -> bytes:
        """Compress image if too large"""
        try:
            from PIL import Image
            import io
            
            # Open image and resize if needed
            image = Image.open(io.BytesIO(image_data))
            
            # Resize to max 1024x1024 while maintaining aspect ratio
            image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
            
            # Save as JPEG with quality 85
            output = io.BytesIO()
            image.save(output, format='JPEG', quality=85)
            return output.getvalue()
            
        except Exception as e:
            print(f"Image compression failed: {e}")
            return image_data
    
    def _save_temp_audio(self, audio_data: bytes) -> str:
        """Save audio data to temporary file"""
        import tempfile
        temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
        temp_file.write(audio_data)
        temp_file.close()
        return temp_file.name
