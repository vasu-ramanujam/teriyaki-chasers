# OpenAI Decision Flow and Confidence Calculation

## Visual Decision Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER UPLOADS PHOTO                           │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                STEP 1: TRY OPENAI GPT-4 VISION                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  🤖 OpenAI API Call                                   │   │
│  │  • Send image to OpenAI                              │   │
│  │  • Wait for response (30s timeout)                  │   │
│  │  • Parse JSON response                              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
              ┌─────────────┐
              │  SUCCESS?   │
              └─────┬───────┘
                    │ NO (API Failed)
                    ▼
        ┌─────────────────────────┐
        │  OPENAI FAILED          │
        │  • Network timeout      │
        │  • API key invalid      │
        │  • Server error         │
        │  • Rate limit exceeded  │
        └─────────────────────────┘
                    │
                    ▼
        ┌─────────────────────────┐
        │  TRY iNATURALIST API    │
        │  (Fallback)             │
        └─────────────────────────┘
                    │
                    ▼
        ┌─────────────────────────┐
        │  iNATURALIST SUCCESS?   │
        └─────────┬───────────────┘
                  │ YES
                  ▼
        ┌─────────────────────────┐
        │  USE iNATURALIST        │
        │  RESULT                 │
        └─────────────────────────┘
                    │ NO
                    ▼
        ┌─────────────────────────┐
        │  RETURN MOCK DATA       │
        │  (Development)         │
        └─────────────────────────┘
                    │ YES (API Succeeded)
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                STEP 2: CHECK CONFIDENCE                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  📊 Confidence Check                                   │   │
│  │  • Extract confidence score from OpenAI response      │   │
│  │  • Check if score ≥ 0.8 (80% threshold)               │   │
│  │  • High confidence = use immediately                  │   │
│  │  • Low confidence = try fallback                      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
              ┌─────────────┐
              │ CONFIDENCE  │
              │   ≥ 0.8?    │
              └─────┬───────┘
                    │ YES (High Confidence)
                    ▼
        ┌─────────────────────────┐
        │  USE OPENAI RESULT      │
        │  • Return immediately   │
        │  • No fallback needed   │
        │  • High accuracy        │
        └─────────────────────────┘
                    │ NO (Low Confidence)
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                STEP 3: TRY iNATURALIST FALLBACK               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  🌿 iNaturalist API Call                               │   │
│  │  • Send image to iNaturalist                           │   │
│  │  • Wait for response (10s timeout)                     │   │
│  │  • Parse JSON response                                │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
              ┌─────────────┐
              │  SUCCESS?   │
              └─────┬───────┘
                    │ YES
                    ▼
        ┌─────────────────────────┐
        │  COMPARE RESULTS         │
        │  • OpenAI vs iNaturalist │
        │  • Choose higher confidence │
        │  • Return best result    │
        └─────────────────────────┘
                    │ NO
                    ▼
        ┌─────────────────────────┐
        │  USE OPENAI RESULT     │
        │  (Even if low confidence) │
        │  • Better than nothing  │
        │  • Flag for review     │
        └─────────────────────────┘
```

## Decision Scenarios

### Scenario 1: OpenAI High Confidence
```
Input: Clear photo of Great Horned Owl
OpenAI: 95% confidence (≥ 0.8)
Decision: Use OpenAI immediately
Result: Great Horned Owl (95% confidence)
```

### Scenario 2: OpenAI Low Confidence, iNaturalist High
```
Input: Blurry photo of Great Horned Owl
OpenAI: 65% confidence (< 0.8)
iNaturalist: 89% confidence
Decision: Try iNaturalist → Compare → Choose iNaturalist
Result: Great Horned Owl (89% confidence)
```

### Scenario 3: OpenAI Fails, iNaturalist Succeeds
```
Input: Photo with API issues
OpenAI: Failed (network error)
iNaturalist: 78% confidence
Decision: OpenAI failed → Try iNaturalist → Use iNaturalist
Result: Great Horned Owl (78% confidence)
```

### Scenario 4: Both APIs Low Confidence
```
Input: Very poor quality photo
OpenAI: 45% confidence (< 0.8)
iNaturalist: 52% confidence
Decision: Try iNaturalist → Compare → Choose iNaturalist
Result: Great Horned Owl (52% confidence)
```

## Confidence Calculation Methods

### OpenAI Confidence:
```python
# Neural network softmax calculation
def calculate_openai_confidence(logits):
    exp_logits = [math.exp(x) for x in logits]
    total = sum(exp_logits)
    probabilities = [x/total for x in exp_logits]
    return max(probabilities)  # Highest probability = confidence
```

### iNaturalist Confidence:
```python
# Computer vision similarity calculation
def calculate_inaturalist_confidence(image_features, species_db):
    similarities = []
    for species in species_db:
        similarity = cosine_similarity(image_features, species.features)
        similarities.append(similarity)
    return max(similarities)  # Highest similarity = confidence
```

## Key Decision Points

1. **OpenAI Success Check**: Did the API call succeed?
2. **Confidence Threshold**: Is confidence ≥ 0.8 (80%)?
3. **Fallback Trigger**: Try iNaturalist if OpenAI fails or low confidence
4. **Comparison Logic**: Choose higher confidence between APIs
5. **Final Fallback**: Use mock data if all APIs fail

The system ensures users always get the most reliable identification possible!

